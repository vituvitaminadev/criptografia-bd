create table login (
    cod_login number not null constraint pk_cod_login primary key,
    login varchar(30) not null,
    senha varchar(150) not null
);

create table acesso (
  data_hora timestamp not null,
  cod_login number not null constraint fk_acesso_login references login(cod_login)
);

--func criptografia

create or replace function FN_CRIPTOGRAFIA(senha varchar2, acrescimo number)

return varchar2
as
result varchar2(150) := '';
aux number := 1;

TYPE RecType IS RECORD
(
    value1   varchar2(150)
);
TYPE TblType IS TABLE OF RecType INDEX BY PLS_INTEGER;
TYPE TblOfTblType IS TABLE OF TblType INDEX BY PLS_INTEGER;
matrix TblOfTblType;
begin
    for i in 0 .. length(senha) - 1 loop
        matrix(mod(i, 3) + 1)(aux).value1 := substr(senha, i + 1, 1);
        if mod(i, 3) = 2 then
            aux := aux + 1;
        end if;
    end loop;

    for x in 1 .. 3 loop
        for y in 1 .. matrix(x).COUNT loop
            result := result || '0' || to_char(to_number(ascii(matrix(x)(y).value1), '99999.999') + acrescimo);
        end loop;
    end loop;
    return result;
end;
/

select FN_CRIPTOGRAFIA('COTEMIG123', 3) from dual;


create or replace function FN_DESCRIPTOGRAFIA(senha varchar2, acrescimo number)
return varchar2
as
result varchar2(150) := '';
strAuxiliar varchar2(150) := '';
aux number := 1;

    TYPE RecType IS RECORD
  (
    value1   NUMBER
  );
  TYPE TblType IS TABLE OF RecType INDEX BY PLS_INTEGER;
  TYPE TblOfTblType IS TABLE OF TblType INDEX BY PLS_INTEGER;
  matrix   TblOfTblType;
    tamanho number := length(senha) / 3;
    aux2 number := 1;
    aux3 number := 0;
begin

    for i in 1 .. tamanho LOOP
        strAuxiliar := strAuxiliar || chr('0'||to_char(to_number(substr(senha, aux, 3), '99999.999') - acrescimo));
        aux := aux + 3;
    END LOOP;
    aux := mod(tamanho, 3);
    for i in 1 .. (tamanho / 3) + 1 loop
        aux2 := i;
        aux3 := aux;
        for x in 1 .. 3 loop
            if length(result) = length(strAuxiliar) then
                exit;
            end if;
            result := result||substr(strAuxiliar, aux2, 1);
            if aux3 > 0 then
                aux2 := aux2 + 1;
                aux3 := aux3 - 1;
            end if;
            aux2 := aux2 + 3;
        end loop;
    end loop;
    return result;
end;
/

select FN_DESCRIPTOGRAFIA('070072074054082080052087076053', 3) from dual;

create or replace procedure PR_INSERE_LOGIN(cod_login number, login varchar2, senha varchar2)
as
    cursor cr_login is select cod_login, login from login;
    data_hora timestamp := SYSTIMESTAMP;
    pass varchar2(150) := 0;

begin
    for x in cr_login loop
        if x.cod_login = cod_login then
            raise_application_error(-20000, 'Código de login já existente!');
        elsif x.login = login then
            raise_application_error(-20001, 'Login já existente!');
        end if;
    end loop;
    select FN_CRIPTOGRAFIA(senha, to_number(to_char(data_hora, 'FF1'))) into pass from dual;
    insert into login values(cod_login, login, pass);
    insert into acesso values(data_hora, cod_login);
end;
/

drop table login;
drop table acesso;
select * from login join acesso on login.cod_login = acesso.cod_login;
insert into login values(1, 'a', '1');
call PR_INSERE_LOGIN(2, 'b', 'COTEMIG123');

create or replace procedure PR_VALIDA_LOGIN(login varchar2, senha varchar2)
as
    cursor cr_login is select cod_login, login, senha from login;
    dt timestamp := SYSTIMESTAMP;
    pass varchar2(150) := '';
    pwd varchar(150) := '';
    aux boolean := true;
begin
    for x in cr_login loop
        if x.login = login then
            select data_hora into dt from acesso where cod_login = x.cod_login;
            select FN_DESCRIPTOGRAFIA(x.senha, to_number(to_char(dt, 'FF1'))) into pass from dual;
            if pass = senha then
                select FN_CRIPTOGRAFIA(senha, to_number(to_char(dt, 'FF1'))) into pwd from dual;
                update login set senha = pwd where cod_login = x.cod_login;
                update acesso set data_hora = dt where cod_login = x.cod_login;
                DBMS_OUTPUT.PUT_LINE('Login efetuado com sucesso!');
                aux := false;
            else
                raise_application_error(-20003, 'Senha incorreta!');
            end if;
        end if;
    end loop;
    if aux then
        raise_application_error(-20002, 'Login não encontrado!');
    end if;
end;
/

call PR_VALIDA_LOGIN('b', 'COTEMIG123');
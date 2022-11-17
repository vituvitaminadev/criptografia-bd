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
linha1 varchar2(150) := '';
linha2 varchar2(150) := '';
linha3 varchar2(150) := '';
aux number := 1;

TYPE RecType IS RECORD
(
    value1   varchar2(150)
);
TYPE TblType IS TABLE OF RecType INDEX BY PLS_INTEGER;
TYPE TblOfTblType IS TABLE OF TblType INDEX BY PLS_INTEGER;
matrix   TblOfTblType;

begin

    FOR i IN 1 .. 3 LOOP
        DBMS_OUTPUT.PUT_LINE(aux);
        FOR j IN 1 .. (length(senha) / 3) + mod(length(senha),3) LOOP
          --matrix(i)(j).value1 := substr(senha, aux, 1);
          if mod(j,3) = 1 then
            matrix(1)(j).value1 := substr(senha, aux, 1);
        elsif mod(j,3) = 2 then
            matrix(2)(j).value1 := substr(senha, aux, 1);
        elsif mod(j,3) = 0 then
            matrix(3)(j).value1 := substr(senha, aux, 1);
        end if;
          DBMS_OUTPUT.PUT('[j: ' || j || ' ' || 'i: ' || i || ']');
          aux := aux + 1;
        END LOOP;
        DBMS_OUTPUT.NEW_LINE;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(aux);

    FOR i IN 1 .. matrix.COUNT LOOP
        FOR j IN 1 .. matrix(i).COUNT LOOP
          DBMS_OUTPUT.PUT( '[' || matrix(i)(j).value1|| ']');
        END LOOP;
        DBMS_OUTPUT.NEW_LINE;
    END LOOP;

    for i in 1 .. (LENGTH(senha)) LOOP
        if mod(i,3) = 1 then
            linha1 := linha1 || '0' || to_char(to_number(ascii(substr(senha, i, 1)), '99999.999') + acrescimo);
        elsif mod(i,3) = 2 then
            linha2 := linha2 || '0' || to_char(to_number(ascii(substr(senha, i, 1)), '99999.999') + acrescimo);
        elsif mod(i,3) = 0 then
            linha3 := linha3 || '0' || to_char(to_number(ascii(substr(senha, i, 1)), '99999.999') + acrescimo);
        end if;
    END LOOP;
    result := linha1||linha2||linha3;
return result;
end;
/

select FN_CRIPTOGRAFIA('COTEMIG123', 3) from dual;


create or replace function FN_DESCRIPTOGRAFIA(senha varchar2, acrescimo number)
return varchar2
as
result varchar2(150) := '';
linha1 varchar2(150) := '';
linha2 varchar2(150) := '';
linha3 varchar2(150) := '';
strAuxiliar varchar2(150) := '';
tamanho number := length(senha) / 3;
aux number := 1;

    TYPE RecType IS RECORD
  (
    value1   NUMBER
  );
  TYPE TblType IS TABLE OF RecType INDEX BY PLS_INTEGER;
  TYPE TblOfTblType IS TABLE OF TblType INDEX BY PLS_INTEGER;
  matrix   TblOfTblType;
begin

    FOR i IN 1 .. 3 LOOP
    FOR j IN 1 .. 4 LOOP
      matrix(i)(j).value1 := i;
    END LOOP;
  END LOOP;

    FOR i IN 1 .. matrix.COUNT LOOP
        FOR j IN 1 .. matrix(i).COUNT LOOP
          DBMS_OUTPUT.PUT( '[' || matrix(i)(j).value1|| ']' || CHR(11) );
        END LOOP;
        DBMS_OUTPUT.NEW_LINE;
    END LOOP;

    for i in 1 .. tamanho LOOP
        strAuxiliar := strAuxiliar || chr('0'||to_char(to_number(substr(senha, aux, 3), '99999.999') - acrescimo));
        --linha3 := linha3 || chr('0'||to_char(to_number(substr(senha, aux, 3), '99999.999') - acrescimo));
        --DBMS_OUTPUT.PUT_LINE(chr('0'||to_char(to_number(substr(senha, aux, 3), '99999.999') - acrescimo)));
        aux := aux + 3;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(strAuxiliar);

    for i in 1 .. length(strAuxiliar) loop
        DBMS_OUTPUT.PUT_LINE(i);
        if mod(i,3) = 1 then
            linha1 := linha1 || substr(strAuxiliar, i, 1);
        elsif mod(i,3) = 2 then
            linha2 := linha2 || substr(strAuxiliar, i, 1);
        elsif mod(i,3) = 0 then
            linha3 := linha3 || substr(strAuxiliar, i, 1);
        end if;
    end loop;
    result := linha1 || linha2 || linha3;
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
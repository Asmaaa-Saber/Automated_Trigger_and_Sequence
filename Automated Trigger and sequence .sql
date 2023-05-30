set serveroutput  on size 1000000
declare 
------start cursor------------
cursor pk_col_cursor is 
select user_cons_columns.table_name ,
 user_cons_columns.column_name,
 user_cons_columns.owner 
from user_constraints 
join user_cons_columns 
on user_cons_columns.table_name = user_constraints.table_name
and user_cons_columns.constraint_name = user_constraints.constraint_name
join user_tab_columns 
on  user_tab_columns.table_name = user_cons_columns.table_name
 and  user_tab_columns.column_name = user_cons_columns.column_name
where user_constraints.constraint_type = 'P' -- to get only primary key
and user_cons_columns.owner ='HR' ----
and   user_tab_columns.data_type = 'NUMBER';  -- only numeric columns
--------End Cursor---------
currunt_max number(10); --- will be assinge to start_with in cursor 
v_seq_count number(10); ---store count of sequences 
begin 
for pk_col_record in pk_col_cursor loop 
------extract Max value from each column -----
execute immediate 'select (max ('|| pk_col_record.column_name ||')) from ' ||pk_col_record.table_name 
            into currunt_max  ;
       currunt_max :=nvl(currunt_max ,0)+1; --- to start with next value from cuurent value in the table 
     --check for existing sequence and drop it  ----
     select count(SEQUENCE_NAME)
        into v_seq_count
        from user_sequences
        where upper(SEQUENCE_NAME)=upper(pk_col_record.Table_NAME||'_seq');
      if  v_seq_count > 0 then 
     Execute immediate ' drop sequence '  || pk_col_record.table_name||'_seq' ;
        v_seq_count:=0;
     end if;
     -------------  4 -- create sequence  start with  (current_value+1)   
execute immediate    'Create sequence '||pk_col_record.table_name ||'_seq' || --name of sequences --
                              ' Start with ' || currunt_max ||
                                ' increment by 1 ';
-- create treggir ''row level ''trigger befor inserting 
execute immediate ' create or replace trigger '||pk_col_record.table_name ||'_trg' ||
                            ' Before Insert on '||pk_col_record.table_name||
                            ' For Each Row '||
                            ' Begin ' ||
                             ':new.'|| pk_col_record.column_name || ' := ' ||pk_col_record.TABLE_NAME||'_seq.nextval;'  ||
                            'END;';
end loop;
end ;
select * from user_errors
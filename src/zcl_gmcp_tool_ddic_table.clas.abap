CLASS zcl_gmcp_tool_ddic_table DEFINITION
  PUBLIC
  INHERITING FROM zcl_gmcp_tool__base FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_local_properties,
             table    TYPE ty_property,
             where    TYPE ty_property,
             max_rows TYPE ty_property,
           END OF ty_local_properties.

    TYPES: BEGIN OF ty_args,
             table    TYPE tabname,
             where    TYPE string,
             max_rows TYPE i,
           END OF ty_args.

    CONSTANTS c_name TYPE string VALUE 'sql_query'.

    METHODS constructor.

  PROTECTED SECTION.
    METHODS fill_tool_definitions REDEFINITION.
    METHODS call_tool             REDEFINITION.

  PRIVATE SECTION.
    METHODS definition_table_read
      RETURNING VALUE(r_result) TYPE ty_tool_definition.

    METHODS build_tool_result
      IMPORTING i_text        TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_gmcp_tool_ddic_table IMPLEMENTATION.
  METHOD constructor.
    super->constructor( i_name = VALUE #( ( c_name ) ) ).
  ENDMETHOD.

  METHOD fill_tool_definitions.
    add_tool_definition( definition_table_read( ) ).
  ENDMETHOD.

  METHOD definition_table_read.
    DATA properties TYPE ty_local_properties.

    properties-table    = VALUE #( type        = 'string'
                                   description = 'Transparent table name' ).
    properties-where    = VALUE #( type        = 'string'
                                   description = 'WHERE clause, optional' ).
    properties-max_rows = VALUE #( type        = 'integer'
                                   description = 'Row limit, default 20' ).

    r_result-name        = 'sql_query'.
    r_result-description = 'Executes a read-only SELECT on a transparent table in OpenSQL'.
    r_result-inputschema-type       = 'object'.
    r_result-inputschema-required   = VALUE #( ( `table` ) ).
    r_result-inputschema-properties = NEW ty_local_properties( properties ).
  ENDMETHOD.

  METHOD call_tool.
    DATA args TYPE ty_args.

    args-max_rows = 20.
    MOVE-CORRESPONDING i_arguments->* TO args.

    SELECT SINGLE tabname FROM dd02l
      WHERE tabname  = @args-table
        AND tabclass = 'TRANSP'
" TODO: variable is assigned but never used (ABAP cleaner)
      INTO @DATA(lv_check).

    IF sy-subrc <> 0.
*    result = build_error_result( |Table { args-table } not found or not a transparent table| ).
      RETURN.
    ENDIF.

    DATA result_tab TYPE REF TO data.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    CREATE DATA result_tab TYPE STANDARD TABLE OF (args-table).
    ASSIGN result_tab->* TO <table>.

    IF args-where IS INITIAL.
      SELECT *
        FROM (args-table)
        INTO CORRESPONDING FIELDS OF TABLE @<table>
        UP TO @args-max_rows ROWS.
    ELSE.
      SELECT *
        FROM (args-table)
        WHERE (args-where)
        INTO CORRESPONDING FIELDS OF TABLE @<table>
        UP TO @args-max_rows ROWS.
    ENDIF.

    DATA(lv_data_json) = /ui2/cl_json=>serialize( data        = <table>
                                                  pretty_name = /ui2/cl_json=>pretty_mode-low_case ).

    result = build_tool_result( lv_data_json ).
  ENDMETHOD.

  METHOD build_tool_result.
    DATA ls_result TYPE zif_gmcp_http_helpers=>ty_tool_result.

    APPEND VALUE #( type = 'text'
                    text = i_text ) TO ls_result-content.
    ls_result-iserror = abap_false.
    result = /ui2/cl_json=>serialize( data          = ls_result
                                      pretty_name   = /ui2/cl_json=>pretty_mode-low_case
                                      name_mappings = VALUE #( ( abap = 'ISERROR' json = 'isError' ) ) ).
  ENDMETHOD.
ENDCLASS.

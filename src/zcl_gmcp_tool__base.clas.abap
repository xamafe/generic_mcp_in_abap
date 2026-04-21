CLASS zcl_gmcp_tool__base DEFINITION
  PUBLIC ABSTRACT
  CREATE PROTECTED.

  PUBLIC SECTION.
    INTERFACES zif_gmcp_tool.

    ALIASES ty_tool_definitions FOR zif_gmcp_tool~ty_tool_definitions.
    ALIASES ty_tool_definition  FOR zif_gmcp_tool~ty_tool_definition.
    ALIASES ty_property         FOR zif_gmcp_tool~ty_property.
    ALIASES get_tool_names      FOR zif_gmcp_tool~get_tool_names.

    METHODS constructor IMPORTING i_name TYPE string_table.

  PROTECTED SECTION.
    METHODS add_tool_definition
      IMPORTING i_definition TYPE ty_tool_definition.

    METHODS fill_tool_definitions ABSTRACT.

    METHODS call_tool ABSTRACT
      IMPORTING i_name        TYPE string
                i_arguments   TYPE REF TO data
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA names            TYPE string_table.
    DATA tool_definitions TYPE ty_tool_definitions.

ENDCLASS.


CLASS zcl_gmcp_tool__base IMPLEMENTATION.
  METHOD constructor.
    names = i_name.
  ENDMETHOD.

  METHOD zif_gmcp_tool~get_tool_definition.
    IF tool_definitions IS INITIAL.
      fill_tool_definitions( ).
    ENDIF.
    result = me->tool_definitions.
  ENDMETHOD.

  METHOD add_tool_definition.
    APPEND INITIAL LINE TO tool_definitions REFERENCE INTO DATA(newline).
    MOVE-CORRESPONDING i_definition TO newline->*.
  ENDMETHOD.

  METHOD zif_gmcp_tool~get_tool_names.
    r_result = me->names.
  ENDMETHOD.

  METHOD zif_gmcp_tool~execute.
    fill_tool_definitions( ).
    IF line_exists( tool_definitions[ name = i_name ] ).
      result = call_tool( i_name      = i_name
                          i_arguments = i_arguments ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.

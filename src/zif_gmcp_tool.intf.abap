INTERFACE zif_gmcp_tool
  PUBLIC.
  INTERFACES zif_gmcp_http_helpers.

  ALIASES ty_tool_definitions FOR zif_gmcp_http_helpers~ty_tool_definitions.
  ALIASES ty_tool_definition  FOR zif_gmcp_http_helpers~ty_tool_definition.
  ALIASES ty_property         FOR zif_gmcp_http_helpers~ty_property.

  METHODS get_tool_definition
    RETURNING VALUE(result) TYPE ty_tool_definitions.

  METHODS execute
    IMPORTING i_name        TYPE string
              i_arguments   TYPE REF TO data
    RETURNING VALUE(result) TYPE string.

  METHODS get_tool_names RETURNING VALUE(r_result) TYPE string_table.

ENDINTERFACE.

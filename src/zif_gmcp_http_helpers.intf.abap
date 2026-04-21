INTERFACE zif_gmcp_http_helpers
  PUBLIC.

  CONSTANTS: BEGIN OF protocol,
               version TYPE string VALUE '2024-11-05' ##NO_TEXT,
               jsonrpc TYPE string VALUE '2.0'        ##NO_TEXT,
             END OF protocol.

  CONSTANTS: BEGIN OF server,
               name    TYPE string VALUE 'abap-mcp' ##NO_TEXT,
               version TYPE string VALUE '1.0.0'    ##NO_TEXT,
             END OF server.

  CONSTANTS c_empty_object TYPE string VALUE '{}' ##NO_TEXT.
  CONSTANTS c_init_result  TYPE string
            VALUE '{"protocolVersion":"2024-11-05","serverInfo":{"name":"abap-mcp","version":"1.0.0"},"capabilities":{"tools":{}}}' ##NO_TEXT.

  TYPES mcp_id TYPE i. " Claude uses integer... may change?!?

  " request from agent
  TYPES: BEGIN OF ty_request,
           jsonrpc TYPE string,
           id      TYPE mcp_id,
           method  TYPE string,
         END OF ty_request.

*  TYPES: BEGIN OF ty_error_body,
*           code    TYPE i,
*           message TYPE string,
*         END OF ty_error_body.

  " Tool capabilities
  TYPES: BEGIN OF ty_property,          " Parameter definition in ty_input_schema-properties
           type        TYPE string,
           description TYPE string,
         END OF ty_property.

  TYPES: BEGIN OF ty_input_schema,
           type       TYPE string,       " 'object'
           properties TYPE REF TO data,  " tool-specific structure
           required   TYPE string_table, " JSON Array ["table"]
         END OF ty_input_schema.

  TYPES: BEGIN OF ty_tool_definition,
           name        TYPE string,
           description TYPE string,
           inputschema TYPE ty_input_schema, " name_mapping
         END OF ty_tool_definition.

  TYPES ty_tool_definitions TYPE STANDARD TABLE OF ty_tool_definition WITH EMPTY KEY.

  TYPES: BEGIN OF ty_capabilities,
           tools TYPE ty_tool_definitions,
         END OF ty_capabilities.

  " --> result
  TYPES: BEGIN OF ty_server_info,
           name    TYPE string,
           version TYPE string,
         END OF ty_server_info.

  TYPES: BEGIN OF ty_result,
           protocolversion TYPE string,          " name_mapping
           serverinfo      TYPE ty_server_info,  " name_mapping
           capabilities    TYPE ty_capabilities,
         END OF ty_result.

  TYPES: BEGIN OF ty_call_params,
           name      TYPE string,
           arguments TYPE REF TO DATA,
         END OF ty_call_params.

  TYPES: BEGIN OF ty_call,
           params TYPE ty_call_params,
         END OF ty_call.

TYPES: BEGIN OF ty_content_item,
         type TYPE string,
         text TYPE string,
       END OF ty_content_item.
TYPES ty_content TYPE STANDARD TABLE OF ty_content_item WITH EMPTY KEY.

TYPES: BEGIN OF ty_tool_result,
         content TYPE ty_content,
         iserror TYPE abap_bool,   " name_mapping
       END OF ty_tool_result.
ENDINTERFACE.

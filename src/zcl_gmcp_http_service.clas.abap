CLASS zcl_gmcp_http_service DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS: BEGIN OF method,
                 delete TYPE string VALUE 'DELETE' ##NO_TEXT,
                 get    TYPE string VALUE 'GET' ##NO_TEXT,
                 post   TYPE string VALUE 'POST' ##NO_TEXT,
                 put    TYPE string VALUE 'PUT' ##NO_TEXT,
               END OF method.

    INTERFACES if_http_extension.
    INTERFACES zif_gmcp_http_helpers.

    ALIASES ty_request      FOR zif_gmcp_http_helpers~ty_request.
    ALIASES ty_capabilities FOR zif_gmcp_http_helpers~ty_capabilities.
    ALIASES ty_call         FOR zif_gmcp_http_helpers~ty_call.
    ALIASES mcp_id          FOR zif_gmcp_http_helpers~mcp_id.

  PRIVATE SECTION.
    DATA request_header_fields TYPE tihttpnvp.
    DATA request_method        TYPE string.
    DATA request_path_info     TYPE string.
    DATA request_uri           TYPE string.
    DATA request_parameters    TYPE stringtab.
    DATA request_body          TYPE xstring.
    DATA response_body         TYPE string.

    DATA tools                 TYPE STANDARD TABLE OF REF TO zif_gmcp_tool.

    METHODS read_provided_data
      IMPORTING i_request TYPE REF TO if_http_request.

    METHODS handle_get.
    METHODS handle_post.

    METHODS dispatch_initialize
      RETURNING VALUE(result) TYPE string.

    METHODS parse_answer_to_json_mapped
      IMPORTING i_answer      TYPE any
      RETURNING VALUE(result) TYPE string.

    METHODS build_jsonrpc_result
      IMPORTING i_id            TYPE mcp_id
                i_answer_json   TYPE string
      RETURNING VALUE(r_result) TYPE string.

    METHODS dispatch_ping
      RETURNING VALUE(r_result) TYPE string.

    METHODS dispatch_tools_list
      RETURNING VALUE(r_result) TYPE string.

    TYPES ty_relevant_classes TYPE STANDARD TABLE OF seoclsname WITH DEFAULT KEY.

    METHODS read_relevant_tool_class_names
      RETURNING VALUE(result) TYPE ty_relevant_classes
      RAISING   cx_class_not_existent.

    METHODS dispatch_tools_call
      IMPORTING i_body          TYPE string
      RETURNING VALUE(r_result) TYPE string.

ENDCLASS.


CLASS zcl_gmcp_http_service IMPLEMENTATION.
  METHOD if_http_extension~handle_request.
    read_provided_data( server->request ).
    CASE request_method.
      WHEN method-post. "... mostly
        handle_post( ).
      WHEN method-get. " status
        handle_get( ).
      WHEN OTHERS.
        " D.O.N.T. T.E.L.L. M.E. W.H.A.T T.O. D.O. !!!!
        server->response->set_status( code   = cl_rest_status_code=>gc_client_error_meth_not_allwd
                                      reason = 'Not allowed' ).
        server->response->set_cdata( data = 'Dont do that again!' ).
        RETURN.
    ENDCASE.

    IF response_body IS NOT INITIAL.
      server->response->set_status( code   = cl_rest_status_code=>gc_success_ok
                                    reason = 'Ok.' ).
      server->response->set_content_type( if_rest_media_type=>gc_appl_json ).
      server->response->set_cdata( data = response_body ).
    ENDIF.
  ENDMETHOD.

  METHOD read_provided_data.
    CONSTANTS parameter_seperator TYPE string VALUE '&' ##NO_TEXT.

    i_request->get_header_fields( CHANGING fields = request_header_fields ).
    request_method = i_request->get_header_field( '~request_method' ).
    request_path_info = i_request->get_header_field( '~path_info' ).
    request_uri = i_request->get_header_field( '~request_uri' ).
    DATA(request_query_string) = i_request->get_header_field( '~query_string' ).
    SPLIT request_query_string AT parameter_seperator INTO TABLE request_parameters.
    request_body = i_request->get_data( ).
  ENDMETHOD.

  METHOD handle_get.
    CASE request_uri.
      WHEN '/.well-known/oauth-authorization-server'.
        response_body = '{"error":"not_supported"}'.
      WHEN OTHERS.
        response_body = |It works!|.
    ENDCASE.
  ENDMETHOD.

  METHOD handle_post.
    DATA envelope TYPE ty_request.

    DATA(body) = cl_abap_codepage=>convert_from( source = request_body ).
    /ui2/cl_json=>deserialize( EXPORTING json = body
                               CHANGING  data = envelope ).

    CASE envelope-method.
      WHEN 'initialize'.
        response_body = dispatch_initialize( ).

      WHEN 'ping'.
        response_body = dispatch_ping( ).

      WHEN 'notifications/initialized'.
        " Notification laut Spec → keine Antwort. Caller prüft IS NOT INITIAL.
        RETURN.

      WHEN 'tools/list'.
        response_body = dispatch_tools_list( ).

      WHEN 'tools/call'.
        response_body = dispatch_tools_call( body ).

      WHEN OTHERS.
*      response_body = build_jsonrpc_error(
*                        iv_id      = ls_envelope-id
*                        iv_code    = -32601
*                        iv_message = 'Method not found' ).
    ENDCASE.
    response_body = build_jsonrpc_result( i_id          = envelope-id
                                          i_answer_json = response_body ).
  ENDMETHOD.

  METHOD dispatch_initialize.
    result = zif_gmcp_http_helpers=>c_init_result.
  ENDMETHOD.

  METHOD parse_answer_to_json_mapped.
    result = /ui2/cl_json=>serialize(
                 data          = i_answer
                 pretty_name   = /ui2/cl_json=>pretty_mode-low_case
                 name_mappings = VALUE #( ( abap = 'PROTOCOLVERSION' json = 'protocolVersion' )
                                          ( abap = 'SERVERINFO'      json = 'serverInfo'      )
                                          ( abap = 'ISERROR'         json = 'isError'         )
                                          ( abap = 'INPUTSCHEMA'     json = 'inputSchema'     ) ) ).
  ENDMETHOD.

  METHOD build_jsonrpc_result.
    r_result = |\{"jsonrpc":"{ zif_gmcp_http_helpers=>protocol-jsonrpc }","id":{ i_id },"result":{ i_answer_json }\}|.
  ENDMETHOD.

  METHOD dispatch_ping.
    r_result = zif_gmcp_http_helpers=>c_empty_object.
  ENDMETHOD.

  METHOD dispatch_tools_list.
    DATA relevant_classes TYPE STANDARD TABLE OF seoclsname.
    DATA tool_result      TYPE ty_capabilities.

    relevant_classes = read_relevant_tool_class_names( ).
    LOOP AT relevant_classes INTO DATA(class).
      APPEND INITIAL LINE TO tools ASSIGNING FIELD-SYMBOL(<tool>).
      CREATE OBJECT <tool> TYPE (class).
      APPEND LINES OF <tool>->get_tool_definition( ) TO tool_result-tools.
    ENDLOOP.

    r_result = parse_answer_to_json_mapped( tool_result ).
  ENDMETHOD.

  METHOD read_relevant_tool_class_names.
    DATA(intf) = CAST cl_oo_interface( cl_oo_interface=>get_instance( clsname = 'ZIF_GMCP_TOOL' ) ).
    DATA(classes) = intf->get_implementing_classes( ).

    LOOP AT classes INTO DATA(classname).
      DATA(cls) = CAST cl_oo_class( cl_oo_class=>get_instance( classname-clsname ) ).
      IF cls->is_abstract( ) = abap_false.
        APPEND classname-clsname TO result.
      ELSE.

        DATA(subclss) = cls->get_subclasses( ).
        LOOP AT subclss INTO DATA(subcls).
          APPEND subcls TO result.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD dispatch_tools_call.
    DATA call             TYPE ty_call.
    DATA relevant_classes TYPE STANDARD TABLE OF seoclsname.
    DATA was_executed     TYPE abap_bool.

    /ui2/cl_json=>deserialize( EXPORTING json = i_body
                               CHANGING  data = call ).

    relevant_classes = read_relevant_tool_class_names( ).

    LOOP AT relevant_classes INTO DATA(class).
      APPEND INITIAL LINE TO tools ASSIGNING FIELD-SYMBOL(<tool>).
      CREATE OBJECT <tool> TYPE (class).
      LOOP AT <tool>->get_tool_definition( ) INTO DATA(tool).
        IF tool-name = call-params-name.

          data(typename) = class && '=>TY_ARGS'.

           CREATE DATA call-params-arguments TYPE (typename).
          /ui2/cl_json=>deserialize( EXPORTING json = i_body
                           CHANGING  data = call ).

          r_result = <tool>->execute( i_name      = call-params-name
                                      i_arguments = call-params-arguments ).
          was_executed = abap_true.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF was_executed = abap_true.
        EXIT.
      ENDIF.
    ENDLOOP.
    IF r_result IS INITIAL.
      r_result = '{"content":[{"type":"text","text":"Unknown tool"}],"isError":true}'.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

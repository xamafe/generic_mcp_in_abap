# ABAP MCP Server (zgeneric_mcp)

Ein minimaler [Model Context Protocol](https://modelcontextprotocol.io/) Server, implementiert in ABAP, der Claude Code direkten Zugriff auf SAP-interne Daten ermöglicht.

## Architektur

### Transport
- **HTTP via ICF** – ein einzelner ICF-Service-Pfad, alle MCP-Anfragen kommen als `POST`
- **Streamable HTTP Transport** (MCP Spec 2025-03-26) – synchrone JSON-RPC 2.0 Antworten, kein SSE

### Implementierte MCP-Methoden
| Methode | Beschreibung |
|---|---|
| `initialize` | Handshake, gibt `protocolVersion`, `serverInfo` und `capabilities` zurück |
| `ping` | Liveness-Check |
| `notifications/initialized` | Wird ignoriert (Notification, keine Antwort) |
| `tools/list` | Gibt alle registrierten Tool-Definitionen zurück |
| `tools/call` | Führt ein Tool aus und gibt das Ergebnis als `content[]` zurück |

### Klassen-Übersicht

```
zcl_gmcp_http_service       ICF Handler – JSON-RPC Dispatcher
zif_gmcp_http_helpers       Interface – alle gemeinsamen Typen und Konstanten
zif_gmcp_tool               Interface – Vertrag für Tool-Klassen
zcl_gmcp_tool__base         Abstrakte Basisklasse für Tools (lazy init, Registry)
zcl_gmcp_tool_ddic_table    Konkretes Tool: SQL-Abfragen auf transparente Tabellen
```

## Tool-Erweiterung

Neue Tools werden als Klasse implementiert die `zif_gmcp_tool` implementiert und von `zcl_gmcp_tool__base` erbt. Der Dispatcher findet alle implementierenden Klassen automatisch über `CL_OO_INTERFACE→GET_IMPLEMENTING_CLASSES`.

```abap
" Minimale neue Tool-Klasse
CLASS zcl_gmcp_tool_my_tool DEFINITION
  INHERITING FROM zcl_gmcp_tool__base PUBLIC FINAL CREATE PUBLIC.
  PROTECTED SECTION.
    METHODS fill_tool_definitions REDEFINITION.
ENDCLASS.
```

## Verfügbare Tools

### `sql_query`
Führt einen read-only `SELECT` auf einer transparenten SAP-Tabelle aus.

| Parameter | Typ | Pflicht | Beschreibung |
|---|---|---|---|
| `table` | string | ja | Tabellenname (nur TRANSP) |
| `where` | string | nein | WHERE-Klausel in OpenSQL |
| `max_rows` | integer | nein | Zeilenlimit, Default 20 |

## Anbindung Claude Code

```json
// .mcp.json im Projektverzeichnis
{
  "mcpServers": {
    "abap-mcp": {
      "type": "http",
      "url": "http://<host>:<port>/sap/bc/zgeneric_mcp",
      "headers": {
        "Authorization": "Basic <base64 user:password>"
      }
    }
  }
}
```

## Sicherheitshinweise

- Der ICF-Service läuft unter einem hinterlegten SAP-User – dessen Berechtigungen sind die einzige Schranke
- `sql_query` prüft ob die Tabelle vom Typ `TRANSP` ist
- Die WHERE-Klausel wird dynamisch ausgeführt – der ICF-User sollte **keine** Berechtigungen auf kritische Tabellen haben

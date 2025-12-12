open Core_types

module Html = struct
  type attr = string * string

  type t =
    | Text of string
    | Fragment of t list
    | Element of { tag : string; attrs : attr list; children : t list }

  type document = { title : string; head : t list; body : t }

  let rec to_string = function
    | Text s -> s
    | Element { tag; attrs; children } ->
        let attrs_str =
          String.concat " "
            (List.map (fun (k, v) -> Printf.sprintf "%s=\"%s\"" k v) attrs)
        in
        let children_str = String.concat "" (List.map to_string children) in
        Printf.sprintf "<%s %s>%s</%s>" tag attrs_str children_str tag
    | Fragment nodes -> String.concat "" (List.map to_string nodes)

  let render_document doc =
    Printf.sprintf
      "<!DOCTYPE html>\n\
       <html>\n\
       <head>\n\
       <title>%s</title>\n\
       %s\n\
       </head>\n\
       <body>\n\
       %s\n\
       </body>\n\
       </html>"
      doc.title
      (String.concat "\n" (List.map to_string doc.head))
      (to_string doc.body)
end

module Page = struct
  type breadcrumb = { label : string; href : string option }
  type section = { id : string; title : string; content : Html.t }

  type table_page = {
    table_name : string;
    breadcrumbs : breadcrumb list;
    quick_stats : (string * string) list; (* label, value *)
    sections : section list;
    related_tables : string list;
  }

  type index_page = {
    database_name : string;
    search_enabled : bool;
    table_groups : (string * string list) list; (* domain, tables *)
    statistics : (string * int) list;
  }

  (* Each type knows how to render itself *)
  let breadcrumbs_to_html crumbs =
    let open Html in
    Element
      {
        tag = "nav";
        attrs = [ ("class", "breadcrumbs") ];
        children =
          List.map
            (fun crumb ->
              match crumb.href with
              | Some href ->
                  Element
                    {
                      tag = "a";
                      attrs = [ ("href", href) ];
                      children = [ Text crumb.label ];
                    }
              | None ->
                  Element
                    {
                      tag = "span";
                      attrs = [ ("class", "current") ];
                      children = [ Text crumb.label ];
                    })
            crumbs;
      }

  let quick_stats_to_html stats =
    let open Html in
    Element
      {
        tag = "div";
        attrs = [ ("class", "quick-stats") ];
        children =
          List.map
            (fun (label, value) ->
              Element
                {
                  tag = "div";
                  attrs = [ ("class", "stat") ];
                  children =
                    [
                      Element
                        {
                          tag = "strong";
                          attrs = [];
                          children = [ Text value ];
                        };
                      Element
                        { tag = "small"; attrs = []; children = [ Text label ] };
                    ];
                })
            stats;
      }

  let section_to_html section =
    let open Html in
    Element
      {
        tag = "section";
        attrs = [ ("id", section.id) ];
        children =
          [
            Element
              { tag = "h2"; attrs = []; children = [ Text section.title ] };
            section.content;
          ];
      }

  let table_page_to_html page =
    let open Html in
    {
      title = page.table_name ^ " - Database Documentation";
      head =
        [
          Element
            {
              tag = "link";
              attrs = [ ("rel", "stylesheet"); ("href", "../static/style.css") ];
              children = [];
            };
        ];
      body =
        Fragment
          [
            breadcrumbs_to_html page.breadcrumbs;
            Element
              { tag = "h1"; attrs = []; children = [ Text page.table_name ] };
            quick_stats_to_html page.quick_stats;
            Fragment (List.map section_to_html page.sections);
          ];
    }
end

module HtmLGen = struct
  let column_to_row (col : Column.t) =
    let open Html in
    Element
      {
        tag = "tr";
        attrs = [];
        children =
          [
            Element
              {
                tag = "td";
                attrs = [];
                children =
                  [
                    Element
                      { tag = "code"; attrs = []; children = [ Text col.name ] };
                  ];
              };
            Element
              { tag = "td"; attrs = []; children = [ Text col.data_type ] };
            Element
              {
                tag = "td";
                attrs = [];
                children =
                  [ Text (if col.is_nullable then "NULL" else "NOT NULL") ];
              };
          ];
      }

  let columns_to_html columns =
    let open Html in
    Element
      {
        tag = "table";
        attrs = [ ("class", "columns-table") ];
        children =
          Element
            {
              tag = "thead";
              attrs = [];
              children =
                [
                  Element
                    {
                      tag = "tr";
                      attrs = [];
                      children =
                        [
                          Element
                            {
                              tag = "th";
                              attrs = [];
                              children = [ Text "Name" ];
                            };
                          Element
                            {
                              tag = "th";
                              attrs = [];
                              children = [ Text "Type" ];
                            };
                          Element
                            {
                              tag = "th";
                              attrs = [];
                              children = [ Text "Constraints" ];
                            };
                        ];
                    };
                ];
            }
          :: List.map column_to_row columns;
      }

  let build_columns_section (table : Table.t) : Page.section =
    {
      id = "columns";
      title = "Columns";
      content = columns_to_html table.columns;
    }

  let build_table_page (table : Table.t) : Page.table_page =
    {
      table_name = table.name;
      breadcrumbs =
        [
          { label = "Home"; href = Some "../index.html" };
          { label = "Tables"; href = Some "../index.html#tables" };
          { label = table.name; href = None };
        ];
      quick_stats =
        [
          ("columns", string_of_int (List.length table.columns));
          ("indexes", string_of_int (List.length table.indexes));
          ("relationships", string_of_int (List.length table.foreign_keys));
        ];
      sections =
        [
          build_columns_section table;
          (* build_relationships_section table schema; *)
          (* build_indexes_section table; *)
        ];
      related_tables = [];
      (* get_related_tables table schema; *)
    }
end

module Html : sig
  type attr = string * string

  type t =
    | Text of string
    | Fragment of t list
    | Element of { tag : string; attrs : attr list; children : t list }

  type document = { title : string; head : t list; body : t }

  val to_string : t -> string
  val render_document : document -> string
end

module Page : sig
  type breadcrumb = { label : string; href : string option }
  type section = { id : string; title : string; content : Html.t }

  type table_page = {
    table_name : string;
    breadcrumbs : breadcrumb list;
    quick_stats : (string * string) list;
    sections : section list;
    related_tables : string list;
  }

  type index_page = {
    database_name : string;
    search_enabled : bool;
    table_groups : (string * string list) list;
    statistics : (string * int) list;
  }

  val breadcrumbs_to_html : breadcrumb list -> Html.t
  val quick_stats_to_html : (string * string) list -> Html.t
  val section_to_html : section -> Html.t
  val table_page_to_html : table_page -> Html.document
end

module HtmLGen : sig
  val column_to_row : Core_types.Column.t -> Html.t
  val columns_to_html : Core_types.Column.t list -> Html.t
  val build_columns_section : Core_types.Table.t -> Page.section
  val build_table_page : Core_types.Table.t -> Page.table_page
end

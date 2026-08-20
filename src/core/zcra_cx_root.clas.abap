class ZCRA_CX_ROOT definition
  public
  inheriting from CX_STATIC_CHECK
  create public .

  public section.

    "! Optional free-text technical error message.
    data mv_text type string read-only .

    methods constructor
      importing
        !textid   like textid optional
        !previous like previous optional
        !iv_text  type string optional .

    methods get_text redefinition .

  protected section.
  private section.
endclass.



class ZCRA_CX_ROOT implementation.

  method constructor.
    super->constructor( textid = textid previous = previous ).
    mv_text = iv_text.
  endmethod.

  method get_text.
    if mv_text is not initial.
      result = mv_text.
    else.
      result = super->get_text( ).
    endif.
  endmethod.

endclass.

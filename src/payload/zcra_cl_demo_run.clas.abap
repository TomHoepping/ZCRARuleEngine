"! Runnable example / debug shell for the ZCRA Rule Engine.
"! Run it in ADT: right-click -> Run As -> ABAP Application (Console) (F9).
"! It wires the whole framework end-to-end and prints the result + engine trace,
"! so developers can set a breakpoint anywhere and step through a real run:
"!   determination registry -> in-memory logger -> context -> engine.run().
"! Copy this into your own session/class to integrate the engine.
class zcra_cl_demo_run definition
  public
  final
  create public .

  public section.
    interfaces if_oo_adt_classrun .
  private section.
    "! Demo process id (any value; the determination registry keys on it).
    constants c_process type zcra_d_process_id value 'EXAMPLE'.
endclass.



class zcra_cl_demo_run implementation.

  method if_oo_adt_classrun~main.

    " 1) Central determination registry + the demo process determination.
    data(lo_registry) = new zcra_cl_determination( ).
    lo_registry->register( iv_process = c_process
                           io_det     = new zcra_cl_det_example( ) ).

    " 2) In-memory logger so we can print the engine trace afterwards.
    "    Swap for new zcra_cl_log_bal( ) to write to SLG1 instead.
    data(lo_logger) = new zcra_cl_log_memory( ).

    " 3) Context — empty graph; the sample flag starts unset.
    data(lo_context) = new zcra_cl_context( ).

    " 4) Engine (logger is optional; defaults to the no-op logger).
    data(lo_engine) = new zcra_cl_engine( io_determination = lo_registry
                                          io_logger        = lo_logger ).

    " 5) Run the pipeline: VALIDATION_PRE -> TRANSFORMATION -> VALIDATION_POST.
    out->write( |=== ZCRA Rule Engine demo: process { c_process } ===| ).
    data lo_result type ref to zcra_cl_result.
    try.
        lo_result = lo_engine->run( iv_process = c_process
                                    io_context = lo_context ).
      catch zcra_cx_rule_kind into data(lx_kind).
        out->write( |ERROR - rule kind/bucket mismatch: { lx_kind->get_text( ) }| ).
        return.
    endtry.

    " 6) Result messages.
    out->write( |--- result messages ({ lines( lo_result->get_messages( ) ) }) ---| ).
    loop at lo_result->get_messages( ) into data(ls_msg).
      out->write( |{ ls_msg-type }  { ls_msg-id }/{ ls_msg-number }  { ls_msg-message_v1 }| ).
    endloop.
    out->write( |stop requested: { lo_result->is_stop_requested( ) }   has errors: { lo_result->has_errors( ) }| ).

    " 7) Engine trace captured by the in-memory logger.
    out->write( `--- engine trace ---` ).
    loop at lo_logger->get_entries( ) into data(ls_e).
      case ls_e-event.
        when zcra_cl_log_memory=>gc_event-rule.
          out->write( |RULE      { ls_e-rule_id } (kind { ls_e-kind }) applicable={ ls_e-applicable } msgs={ ls_e-msg_count }| ).
        when zcra_cl_log_memory=>gc_event-snapshot.
          out->write( |SNAPSHOT  { ls_e-label }| ).
        when others.
          out->write( |{ ls_e-event }| ).
      endcase.
    endloop.

    " 8) Final context state — the transform flipped the sample flag.
    out->write( `--- final context ---` ).
    out->write( |sample flag = '{ lo_context->zcra_if_context~get_new_graph( )-shell_placeholder }'| ).

  endmethod.

endclass.

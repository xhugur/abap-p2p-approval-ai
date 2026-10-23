CLASS zcl_p2p_load_master DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_p2p_load_master IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DELETE FROM zp2p_cmpcode.
    DELETE FROM zp2p_costctr.
    DELETE FROM zp2p_approver.

    INSERT zp2p_cmpcode FROM TABLE @( VALUE #(
      ( company_code = '1000' company_name = 'Demo Turkiye' currency = 'TRY' )
      ( company_code = '2000' company_name = 'Demo Germany' currency = 'EUR' ) ) ).

    INSERT zp2p_costctr FROM TABLE @( VALUE #(
      ( cost_center = 'CC1001' company_code = '1000' description = 'IT Department' )
      ( cost_center = 'CC1002' company_code = '1000' description = 'Finance Department' )
      ( cost_center = 'CC1003' company_code = '1000' description = 'Marketing Department' ) ) ).

    INSERT zp2p_approver FROM TABLE @( VALUE #(
  ( approver_id = cl_abap_context_info=>get_user_technical_name( )
    approval_limit = 15000 currency = 'TRY' ) ) ).

    SELECT COUNT(*) FROM zp2p_cmpcode INTO @DATA(lv_cc).
    SELECT COUNT(*) FROM zp2p_costctr INTO @DATA(lv_kc).
    out->write( |Company codes: { lv_cc }, Cost centers: { lv_kc }| ).
  ENDMETHOD.
ENDCLASS.

CLASS zcl_p2p_test_po DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.

CLASS zcl_p2p_test_po IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    MODIFY ENTITIES OF zr_p2p_po_hdr
      ENTITY PurchaseOrder
        CREATE FIELDS ( Supplier CompanyCode Currency )
        WITH VALUE #( ( %cid = 'PO1' Supplier = 'SUP0000001'
                        CompanyCode = '1000' Currency = 'TRY' ) )
        CREATE BY \_Item FIELDS ( ItemNo Description Quantity Unit UnitPrice CostCenter )
        WITH VALUE #( ( %cid_ref = 'PO1'
                        %target = VALUE #( ( %cid = 'IT1' ItemNo = '00010'
                                             Description = 'Laptop'
                                             Quantity = 10 Unit = 'ST'
                                             "UnitPrice = 1000 CostCenter = 'CC1001' ) ) ) )
                                             UnitPrice = 1000 CostCenter = 'XXXX' ) ) ) )
      MAPPED DATA(mapped) FAILED DATA(failed) REPORTED DATA(reported).

    COMMIT ENTITIES RESPONSE OF zr_p2p_po_hdr
      FAILED DATA(failed_c) REPORTED DATA(reported_c).

    IF failed_c IS NOT INITIAL OR failed IS NOT INITIAL.
      out->write( 'FAILED, mesajlari kontrol et' ).
      out->write( reported_c ).
    ENDIF.

    SELECT FROM zp2p_po_hdr FIELDS po_uuid, status, total_amount, currency INTO TABLE @DATA(hdr).
    SELECT FROM zp2p_po_itm FIELDS item_no, quantity, unit_price, net_amount, currency, cost_center
      INTO TABLE @DATA(itm).
    out->write( hdr ).
    out->write( itm ).
  ENDMETHOD.
ENDCLASS.

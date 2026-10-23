CLASS zcl_p2p_test_approval DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    METHODS create_po IMPORTING iv_price TYPE i RETURNING VALUE(rv_uuid) TYPE sysuuid_x16.
ENDCLASS.

CLASS zcl_p2p_test_approval IMPLEMENTATION.
  METHOD create_po.
    MODIFY ENTITIES OF zr_p2p_po_hdr
      ENTITY PurchaseOrder
        CREATE FIELDS ( Supplier CompanyCode Currency )
        WITH VALUE #( ( %cid = 'PO1' Supplier = 'SUP0000001' CompanyCode = '1000' Currency = 'TRY' ) )
        CREATE BY \_Item FIELDS ( Description Quantity Unit UnitPrice CostCenter )
        WITH VALUE #( ( %cid_ref = 'PO1'
                        %target = VALUE #( ( %cid = 'IT1' Description = 'Laptop' Quantity = 1
                                             Unit = 'ST' UnitPrice = iv_price
                                             CostCenter = 'CC1001' ) ) ) )
      MAPPED DATA(mapped).
    COMMIT ENTITIES.
    rv_uuid = mapped-purchaseorder[ 1 ]-PoUuid.
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    DATA(uuid_ok)   = create_po( 10000 ).
    DATA(uuid_high) = create_po( 20000 ).

    MODIFY ENTITIES OF zr_p2p_po_hdr
      ENTITY PurchaseOrder
        EXECUTE submit FROM VALUE #( ( PoUuid = uuid_ok ) ( PoUuid = uuid_high ) )
      FAILED DATA(f1) REPORTED DATA(r1).
    COMMIT ENTITIES.

    MODIFY ENTITIES OF zr_p2p_po_hdr
      ENTITY PurchaseOrder
        EXECUTE approve FROM VALUE #( ( PoUuid = uuid_ok ) )
      FAILED DATA(f2) REPORTED DATA(r2).
    COMMIT ENTITIES.

    MODIFY ENTITIES OF zr_p2p_po_hdr
      ENTITY PurchaseOrder
        EXECUTE approve FROM VALUE #( ( PoUuid = uuid_high ) )
      FAILED DATA(f3) REPORTED DATA(r3).

    LOOP AT r3-purchaseorder INTO DATA(rep).
      out->write( rep-%msg->if_message~get_text( ) ).
    ENDLOOP.

    SELECT FROM zp2p_po_hdr FIELDS po_number, status, total_amount, currency
      ORDER BY po_number INTO TABLE @DATA(hdr).
    out->write( hdr ).
  ENDMETHOD.
ENDCLASS.

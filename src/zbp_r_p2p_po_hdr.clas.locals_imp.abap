CLASS lhc_ZR_P2P_PO_HDR DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR zr_p2p_po_hdr RESULT result.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
       keys FOR zr_p2p_po_hdr~setInitialStatus.

    METHODS validateCompanyCode FOR VALIDATE ON SAVE
       keys FOR zr_p2p_po_hdr~validateCompanyCode.

ENDCLASS.

CLASS lhc_ZR_P2P_PO_HDR IMPLEMENTATION.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD setInitialStatus.
    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrder  FIELDS ( Status ) WITH CORRESPONDING #( keys )
    RESULT DATA(orders).

    DELETE orders WHERE status IS NOT INITIAL.
    CHECK orders IS NOT INITIAL.

    MODIFY ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrder UPDATE FIELDS ( Status )
    WITH VALUE #( FOR o IN orders ( %tky = o-%tky Status = 'N' ) ).
  ENDMETHOD.

  METHOD validateCompanyCode.

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrder FIELDS ( CompanyCode )
    WITH CORRESPONDING #( keys )
    RESULT DATA(orders).

    LOOP AT orders INTO DATA(order).
      SELECT COUNT( * ) FROM zp2p_cmpcode
      WHERE company_code = @order-CompanyCode.
      IF sy-subrc NE 0.
        APPEND VALUE #( %tky = order-%tky ) TO failed-purchaseorder.
        APPEND VALUE #( %tky = order-%tky
                        %msg = new_message_with_text(
                                 severity = if_abap_behv_message=>severity-error
                                 text     = |Company code { order-CompanyCode } is not defined| )
                          %element-CompanyCode = if_abap_behv=>mk-on ) TO reported-purchaseorder.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_PurchaseOrderItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateAmounts FOR DETERMINE ON MODIFY
       keys FOR PurchaseOrderItem~calculateAmounts.

    METHODS validateCostCenter FOR VALIDATE ON SAVE
       keys FOR PurchaseOrderItem~validateCostCenter.

ENDCLASS.

CLASS lhc_PurchaseOrderItem IMPLEMENTATION.

  METHOD calculateAmounts.
    " 1) Kalemleri ve bağlı oldukları headerı oku
    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrderItem FIELDS ( PoUuid Quantity UnitPrice )
    WITH CORRESPONDING #( keys )
    RESULT DATA(items).

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrderItem BY \_PurchaseOrder FIELDS ( Currency )
    WITH CORRESPONDING #( keys )
    RESULT DATA(orders).

    " 2) Net tutar = miktar x birim fiyat, para birimi header'dan kopyalanır
    MODIFY ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrderItem UPDATE FIELDS ( NetAmount Currency )
    WITH VALUE #( FOR i IN items
                   ( %tky = i-%tky
                     NetAmount = i-Quantity * i-UnitPrice
                     Currency = VALUE #( orders[ PoUuid = i-PoUuid ]-Currency OPTIONAL ) )

     ).

    " 3) Header toplamı: tüm kalemlerin net tutar toplamı
    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
       ENTITY PurchaseOrder BY \_Item FIELDS ( PoUuid NetAmount ) WITH CORRESPONDING #( orders )
       RESULT DATA(all_items).

    DATA updates TYPE TABLE FOR UPDATE zr_p2p_po_hdr\\PurchaseOrder.
    DATA total   TYPE decfloat34.

    LOOP AT orders INTO DATA(order).
      total = 0.
      LOOP AT all_items INTO DATA(item) WHERE PoUuid = order-PoUuid.
        total = total + item-NetAmount.
      ENDLOOP.
      APPEND VALUE #( %tky = order-%tky TotalAmount = total ) TO updates.
    ENDLOOP.

    MODIFY ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrder UPDATE FIELDS ( TotalAmount ) WITH updates.
  ENDMETHOD.

  METHOD validateCostCenter.
    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrderItem FIELDS ( CostCenter PoUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(items).

    LOOP AT items INTO DATA(item).
      SELECT SINGLE @abap_true FROM zp2p_costctr
        WHERE cost_center = @item-CostCenter
        INTO @DATA(found).
      IF sy-subrc <> 0.
        APPEND VALUE #( %tky = item-%tky ) TO failed-purchaseorderitem.
        APPEND VALUE #( %tky  = item-%tky
                        %path = VALUE #( purchaseorder-%is_draft = item-%is_draft
                                         purchaseorder-PoUuid    = item-PoUuid )
                        %msg  = new_message_with_text(
                                  severity = if_abap_behv_message=>severity-error
                                  text     = |Cost center { item-CostCenter } does not exist| )
                        %element-CostCenter = if_abap_behv=>mk-on ) TO reported-purchaseorderitem.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

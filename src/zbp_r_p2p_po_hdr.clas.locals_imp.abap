CLASS lhc_ZR_P2P_PO_HDR DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations FOR zr_p2p_po_hdr RESULT result.

    METHODS setInitialStatus FOR DETERMINE ON MODIFY
       keys FOR zr_p2p_po_hdr~setInitialStatus.

    METHODS validateCompanyCode FOR VALIDATE ON SAVE
       keys FOR zr_p2p_po_hdr~validateCompanyCode.
    METHODS setPoNumber FOR DETERMINE ON SAVE
       keys FOR PurchaseOrder~setPoNumber.
    METHODS approve FOR MODIFY
       keys FOR ACTION PurchaseOrder~approve RESULT result.

    METHODS reject FOR MODIFY
       keys FOR ACTION PurchaseOrder~reject RESULT result.

    METHODS submit FOR MODIFY
       keys FOR ACTION PurchaseOrder~submit RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      keys REQUEST requested_features FOR PurchaseOrder RESULT result.

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

  METHOD setPoNumber.

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrder FIELDS ( PoNumber ) WITH CORRESPONDING #( keys )
    RESULT DATA(orders).

    DELETE orders WHERE PoNumber IS NOT INITIAL.
    CHECK orders IS NOT INITIAL.

    SELECT MAX( po_number ) FROM zp2p_po_hdr INTO @DATA(lv_max).

    DATA lv_next TYPE n LENGTH 10.
    IF lv_max IS INITIAL.
      lv_next = '4500000000'.
    ELSE.
      lv_next =  lv_max .
    ENDIF.

    DATA updates TYPE TABLE FOR UPDATE zr_p2p_po_hdr\\PurchaseOrder.
    LOOP AT orders INTO DATA(order).
      lv_next = lv_next + 1.
      APPEND VALUE #( %tky = order-%tky PoNumber = lv_next ) TO updates.
    ENDLOOP.

    MODIFY ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrder UPDATE FIELDS ( PoNumber ) WITH updates.

  ENDMETHOD.

  METHOD approve.
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    SELECT SINGLE approval_limit FROM zp2p_approver
      WHERE approver_id = @lv_user INTO @DATA(lv_limit).
    DATA(lv_is_approver) = xsdbool( sy-subrc = 0 ).

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrder FIELDS ( Status TotalAmount ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    LOOP AT orders INTO DATA(order).
      DATA(lv_error) = ||.
      IF order-Status <> 'S'.
        lv_error = |Only submitted orders can be approved|.
      ELSEIF lv_is_approver = abap_false.
        lv_error = |User { lv_user } is not an approver|.
      ELSEIF order-TotalAmount > lv_limit.
        lv_error = |Amount exceeds your approval limit|.
      ENDIF.

      IF lv_error IS NOT INITIAL.
        APPEND VALUE #( %tky = order-%tky ) TO failed-purchaseorder.
        APPEND VALUE #( %tky = order-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text = lv_error ) ) TO reported-purchaseorder.
      ELSE.
        MODIFY ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
          ENTITY PurchaseOrder UPDATE FIELDS ( Status )
          WITH VALUE #( ( %tky = order-%tky Status = 'A' ) ).
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrder ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(result_orders).
    result = VALUE #( FOR r IN result_orders ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD reject.
    DATA(lv_user) = cl_abap_context_info=>get_user_technical_name( ).
    SELECT SINGLE approval_limit FROM zp2p_approver
      WHERE approver_id = @lv_user INTO @DATA(lv_limit).
    DATA(lv_is_approver) = xsdbool( sy-subrc = 0 ).

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrder FIELDS ( Status TotalAmount ) WITH CORRESPONDING #( keys )
      RESULT DATA(orders).

    LOOP AT orders INTO DATA(order).
      DATA(lv_error) = ||.
      IF order-Status <> 'S'.
        lv_error = |Only submitted orders can be rejected|.
      ELSEIF lv_is_approver = abap_false.
        lv_error = |User { lv_user } is not an approver|.
      ENDIF.

      IF lv_error IS NOT INITIAL.
        APPEND VALUE #( %tky = order-%tky ) TO failed-purchaseorder.
        APPEND VALUE #( %tky = order-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text = lv_error ) ) TO reported-purchaseorder.
      ELSE.
        MODIFY ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
          ENTITY PurchaseOrder UPDATE FIELDS ( Status )
          WITH VALUE #( ( %tky = order-%tky Status = 'R' ) ).
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrder ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(result_orders).
    result = VALUE #( FOR r IN result_orders ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD submit.
    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
     ENTITY PurchaseOrder FIELDS ( Status ) WITH CORRESPONDING #( keys )
     RESULT DATA(orders).
    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrder BY \_Item FIELDS ( PoUuid ) WITH CORRESPONDING #( orders )
      RESULT DATA(items).

    LOOP AT orders INTO DATA(order).
      DATA(lv_error) = ||.
      IF order-Status <> 'N' AND order-Status <> 'R'.
        lv_error = |Only new or rejected orders can be submitted|.
      ELSEIF NOT line_exists( items[ PoUuid = order-PoUuid ] ).
        lv_error = |Order has no items|.
      ENDIF.

      IF lv_error IS NOT INITIAL.
        APPEND VALUE #( %tky = order-%tky ) TO failed-purchaseorder.
        APPEND VALUE #( %tky = order-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text = lv_error ) ) TO reported-purchaseorder.
      ELSE.
        MODIFY ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
          ENTITY PurchaseOrder UPDATE FIELDS ( Status )
          WITH VALUE #( ( %tky = order-%tky Status = 'S' ) ).
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrder ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(result_orders).
    result = VALUE #( FOR r IN result_orders ( %tky = r-%tky %param = r ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrder FIELDS ( Status )
    WITH CORRESPONDING #( keys )
    RESULT DATA(orders).

    result = VALUE #(
        FOR o IN orders

        LET editable = COND #( WHEN o-Status = 'N' OR o-Status = 'R'
                             THEN if_abap_behv=>fc-o-enabled ELSE  if_abap_behv=>fc-o-disabled )
            submitted = COND #(  WHEN o-Status = 'S'
                              THEN if_abap_behv=>fc-o-disabled ELSE  if_abap_behv=>fc-o-disabled  )
        IN ( %tky = o-%tky
             %action-submit = editable
             %action-approve = submitted
             %action-reject = submitted
             %action-Edit = editable
             %delete = editable
        )
     ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_PurchaseOrderItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calculateAmounts FOR DETERMINE ON MODIFY
       keys FOR PurchaseOrderItem~calculateAmounts.

    METHODS validateCostCenter FOR VALIDATE ON SAVE
       keys FOR PurchaseOrderItem~validateCostCenter.
    METHODS setItemNo FOR DETERMINE ON MODIFY
       keys FOR PurchaseOrderItem~setItemNo.

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

  METHOD setItemNo.

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrderItem BY \_PurchaseOrder FIELDS ( PoUuid ) WITH CORRESPONDING #( keys )
    RESULT DATA(orders).

    READ ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
    ENTITY PurchaseOrder BY \_Item FIELDS ( PoUuid ItemNo ) WITH CORRESPONDING #( keys )
    RESULT DATA(all_items).

    DATA updates TYPE TABLE FOR UPDATE zr_p2p_po_hdr\\PurchaseOrderItem.
    DATA max_no TYPE i.

    LOOP AT orders INTO DATA(order).
      max_no = 0.

      LOOP AT all_items INTO DATA(item) WHERE PoUuid = order-PoUuid.
        IF item-ItemNo > max_no.
          max_no = item-ItemNo.
        ENDIF..
      ENDLOOP.

      LOOP AT all_items INTO item WHERE PoUuid = order-PoUuid AND ItemNo IS INITIAL.
        max_no = max_no + 10.
        APPEND VALUE #( %tky = item-%tky ItemNo = max_no ) TO updates.
      ENDLOOP.

      CHECK updates IS NOT INITIAL.

      MODIFY ENTITIES OF zr_p2p_po_hdr IN LOCAL MODE
      ENTITY PurchaseOrderItem UPDATE FIELDS ( ItemNo ) WITH updates.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

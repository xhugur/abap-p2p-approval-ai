@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'P2P PO Item'
define view entity ZR_P2P_PO_ITM
  as select from zp2p_po_itm
  association to parent ZR_P2P_PO_HDR as _PurchaseOrder
    on $projection.PoUuid = _PurchaseOrder.PoUuid
{
  key item_uuid      as ItemUuid,
      po_uuid        as PoUuid,
      item_no        as ItemNo,
      description    as Description,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      quantity       as Quantity,
      unit           as Unit,
      @Semantics.amount.currencyCode: 'Currency'
      unit_price     as UnitPrice,
      @Semantics.amount.currencyCode: 'Currency'
      net_amount     as NetAmount,
      currency       as Currency,
      cost_center    as CostCenter,
      internal_order as InternalOrder,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      _PurchaseOrder
}

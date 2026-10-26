@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'P2P PO Item (Projection)'
@Metadata.allowExtensions: true
define view entity ZC_P2P_PO_ITM  
as projection on ZR_P2P_PO_ITM
{
    key ItemUuid,
    PoUuid,
    ItemNo,
    Description,
    Quantity,
    Unit,
    UnitPrice,
    NetAmount,
    Currency,
    CostCenter,
    InternalOrder,
    LocalLastChangedAt,
    /* Associations */
    _PurchaseOrder : redirected to parent ZC_P2P_PO_HDR
}

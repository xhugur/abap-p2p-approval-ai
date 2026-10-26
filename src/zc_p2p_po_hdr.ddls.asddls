@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'P2P PO Header (Projection)'
@Metadata.allowExtensions: true
define root view entity ZC_P2P_PO_HDR 
provider contract transactional_query
as projection on ZR_P2P_PO_HDR
{
    key PoUuid,
    PoNumber,
    Supplier,
    CompanyCode,
    TotalAmount,
    Currency,
    Status,
    CreatedBy,
    CreatedAt,
    LocalLastChangedAt,
    LastChangedAt,
    /* Associations */
    _Item : redirected to composition child ZC_P2P_PO_ITM
}

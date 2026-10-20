@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'P2P PO Header'
define root view entity ZR_P2P_PO_HDR
  as select from zp2p_po_hdr
  composition [0..*] of ZR_P2P_PO_ITM as _Item
{
  key po_uuid      as PoUuid,
      po_number    as PoNumber,
      supplier     as Supplier,
      company_code as CompanyCode,
      @Semantics.amount.currencyCode: 'Currency'
      total_amount as TotalAmount,
      currency     as Currency,
      status       as Status,
      @Semantics.user.createdBy: true
      created_by   as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at   as CreatedAt,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Item
}

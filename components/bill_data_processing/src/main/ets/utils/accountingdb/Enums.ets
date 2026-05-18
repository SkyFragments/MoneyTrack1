export enum AccountTableFields {
  ACCOUNT_ID = 'accountId',
  NAME = 'name',
  TYPE = 'type',
  DATE = 'date',
  ACCOUNT_INCOME = 'accountIncome',
  ACCOUNT_EXPENSE = 'accountExpense',
}

export enum TransactionTableFields {
  TRANSACTION_ID = 'transactionId',
  ACCOUNT_ID = 'accountId',
  ASSET_ID = 'assetId',
  TYPE = 'type',
  RESOURCE = 'resource',
  AMOUNT = 'amount',
  DATE = 'date',
  NOTE = 'note',
  EXCLUDED = 'excluded',
}

export enum AssetTableFields {
  ASSET_ID = 'assetId',
  NAME = 'name',
  TYPE = 'type',
  SUBTYPE = 'subType',
  CATEGORY = 'category',
  AMOUNT = 'amount',
  NOTE = 'note',
}

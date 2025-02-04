import React from 'react'
import { Button, Table } from 'antd'
import { useWallet } from '@aptos-labs/wallet-adapter-react';

const { Column } = Table;

const AllPairsTable = ({ data, onRemovePair, openReservesModal, onSelectedPairData }: any) => {
  const { account } = useWallet()

  return (
    <div>
      <h3>All Trading pairs by Creator {account?.address}</h3>
      <Table
        dataSource={data || []}
        onRow={(record, _index) => ({ onClick: () => onSelectedPairData(record)})}
      >
        <Column
          title="Pair Id"
          dataIndex="key"
          key="key"
          render={(value: any) => `${value.slice(0, 10)}...`}
        />
        <Column
          title="From"
          dataIndex="value"
          key="from"
          render={(value: any) => {
            let coinsFrom = ''
            value.coins_from_name.forEach((coinFromName: string) => coinsFrom += coinFromName.split("::")[2] + ", ")
            return coinsFrom.slice(0, -2)
          }}
        />
        <Column
          title="To"
          dataIndex="value"
          key="to"
          render={(value: any) => {
            let coinsTo = ''
            value.coins_to_name.forEach((coinFromName: string) => coinsTo += coinFromName.split("::")[2] + ", ")
            return coinsTo.slice(0, -2)
          }}
        />
        <Column
          title="Exchange Rate"
          dataIndex="value"
          key="exchange_rate"
          // @todo: move this 100 to some Config (update CreatePairForm also)
          render={(value: any) => {
            let exchangeRates = ''
            value.exchange_rates.forEach((exchangeRate: string) => exchangeRates += Number(exchangeRate) / 100 + ", ")
            return exchangeRates.slice(0, -2)
          }}
        />
        <Column
          title="Action"
          key="action"
          render={(_:any, record: any) => (
            <>
              <Button
                onClick={() => onRemovePair(record?.value?.coins_from_name, record?.value?.coins_to_name, record?.key)}
              >
                Remove
              </Button>
              <Button
                style={{ marginLeft: '0.5rem' }}
                onClick={() => {
                  onSelectedPairData(record)
                  openReservesModal()
                }}
              >
                Increase Reserves
              </Button>
            </>
          )}
        />
      </Table>
    </div>
  )
}

export default AllPairsTable

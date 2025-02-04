import React from 'react'
import { Table } from 'antd'

const Decimals = 8

type SwapEventType = {
  coins_from_name: Array<string>,
  coins_to_name: Array<string>,
  coins_from_amount: Array<string>,
  coins_to_amount: Array<string>,
  exchange_rates: Array<string>,
  timestamp: string,
}

const columns = [
  {
    title: 'Coin From',
    dataIndex: 'coins_from_name',
    key: 'coins_from_name',
    render: (value: any) => {
      let fromCoinsNames = ''
      value.forEach((coinFromName: string) => fromCoinsNames += coinFromName.split("::")[2] + ", ")
      return fromCoinsNames.slice(0, -2)
    }
  },
  {
    title: 'Coin To',
    dataIndex: 'coins_to_name',
    key: 'coins_to_name',
    render: (value: any) => {
      let toCoinsNames = ''
      value.forEach((coinToName: string) => toCoinsNames += coinToName.split("::")[2] + ", ")
      return toCoinsNames.slice(0, -2)
    }
  },
  {
    title: 'Coin From Amount',
    dataIndex: 'coins_from_amount',
    key: 'coins_from_amount',
    render: (value: any) => {
      let coinsFromAmount = ''
      value.forEach((coinFromName: string) => coinsFromAmount += (Number(coinFromName) / 10 ** Decimals) + ", ")
      return coinsFromAmount.slice(0, -2)
    }
  },
  {
    title: 'Coin To Name',
    dataIndex: 'coins_to_amount',
    key: 'coins_to_amount',
    render: (value: any) => {
      let coinsToAmount = ''
      value.forEach((coinFromName: string) => coinsToAmount += (Number(coinFromName) / 10 ** Decimals) + ", ")
      return coinsToAmount.slice(0, -2)
    }
  },
  {
    title: 'Exchanage Rate',
    dataIndex: 'exchange_rates',
    key: 'exchange_rates',
    render: (value: Array<string>) => {
      let exchangeRates = ''
      value.forEach((exchangeRate: string) => exchangeRates += Number(exchangeRate) / 100 + ", ")
      return exchangeRates.slice(0, -2)
    }
  },
  {
    title: 'Date',
    dataIndex: 'timestamp',
    key: 'timestamp',
    render: (time: string) => new Date(Number(time) * 1000).toISOString().split('T')[0],
  }
];

interface SwapEventsTableProps {
  data: Array<SwapEventType>
}

export const SwapEventsTable = ({ data }: SwapEventsTableProps) => (
  <div style={{ marginBottom: '3rem', marginTop: '3rem'}}>
    <h3>All Swap Events</h3>
    <Table dataSource={data || []} columns={columns} />
  </div>
)

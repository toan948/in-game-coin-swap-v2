import React, { useEffect, useState } from "react"
import { Form, Input, Button, Select } from "antd"
import { useWallet } from "@aptos-labs/wallet-adapter-react"
import { AptosClient } from "aptos"
import { useApolloClient } from "@apollo/client"
import Decimal from "decimal.js"

import { CoinBalancesQuery } from './CoinBalance'
import useCoinBalances from "../context/useCoinBalances"
import CONFIG from "../config.json"
import { CoinBalance } from "../context/CoinBalancesProvider"

const { Option } = Select;

const PackageName = "swap_coins"

const DevnetClientUrl = "https://fullnode.devnet.aptoslabs.com/v1"
const TestnetClientUrl = "https://fullnode.testnet.aptoslabs.com"
const client = new AptosClient(CONFIG.network === "devnet" ? DevnetClientUrl : TestnetClientUrl)

const Decimals = 8

export const multipleWithDecimal = (miltiplier: string | number, amount: number | string = 100): string => {
  if (!miltiplier) return ''
  const decimalExchangeRate = new Decimal(miltiplier)
  const validExchangeRate = decimalExchangeRate.times(amount)
  return validExchangeRate.toString()
}

export const formatCoinName = (coinName: string): string => {
  return coinName ? coinName.split("::")[2] : ''
}

const layout = {
  labelCol: { span: 6 },
  wrapperCol: { span: 16 },
};

export const CreatePairForm = ({ getAllTradingPairs }: any) => {
  const { signAndSubmitTransaction } = useWallet()
  const { coinBalances } = useCoinBalances()
  const apolloClient = useApolloClient()
  const [form] = Form.useForm()
  
  const [fromCoinsSelected, setFromCoinsSelected] = useState<Array<any>>([])
  const [toCoinsSelected, setToCoinsSelected] = useState<Array<any>>([])
  const [fromCoinsList, setFromCoinsList] = useState<Array<CoinBalance>>([])
  const [toCoinsList, setToCoinsList] = useState<Array<CoinBalance>>([])

  const [exchangeRateCoinA, setExchangeRateCoinA] = useState('')
  const [exchangeRateCoinB, setExchangeRateCoinB] = useState('')

  useEffect(() => {
    if (coinBalances.length > 0) {
      setFromCoinsList(coinBalances)
      setToCoinsList(coinBalances)
    }
  }, [coinBalances])

  const [coinAAmountReserve, setCoinAAmountReserve] = useState(200)
  const [coinBAmountReserve, setCoinBAmountReserve] = useState(200)
  const [coinCAmountReserve, setCoinCAmountReserve] = useState(200)
  const [coinDAmountReserve, setCoinDAmountReserve] = useState(200)

  const onCreatePair = async () => {
    if (!exchangeRateCoinA || !Number(exchangeRateCoinA)) {
      alert("No exchange rate")
      return
    }

    let pairType = "create_pair"
    const typeArguments: Array<string> = [fromCoinsSelected[0]]
    const args: Array<any> = []

    if (fromCoinsSelected.length === 2 && toCoinsSelected.length === 2) {
      pairType = "create_quadruple_pair"
      typeArguments.push(fromCoinsSelected[1], toCoinsSelected[0], toCoinsSelected[1])
      args.push(
        [multipleWithDecimal(exchangeRateCoinA), multipleWithDecimal(exchangeRateCoinB)],
        multipleWithDecimal(coinAAmountReserve, (10 ** Decimals)),
        multipleWithDecimal(coinBAmountReserve, (10 ** Decimals)),
        multipleWithDecimal(coinCAmountReserve, (10 ** Decimals)),
        multipleWithDecimal(coinDAmountReserve, (10 ** Decimals)),
      )
    } else if (fromCoinsSelected.length === 2 && toCoinsSelected.length === 1) {
      pairType = "create_triple_pair"
      typeArguments.push(fromCoinsSelected[1], toCoinsSelected[0])
      args.push([multipleWithDecimal(exchangeRateCoinA)],
        multipleWithDecimal(coinAAmountReserve, (10 ** Decimals)),
        multipleWithDecimal(coinBAmountReserve, (10 ** Decimals)),
        multipleWithDecimal(coinCAmountReserve, (10 ** Decimals)),
      )
    } else {
      // basic pair
      typeArguments.push(toCoinsSelected[0])
      args.push(
        [multipleWithDecimal(exchangeRateCoinA)],
        multipleWithDecimal(coinAAmountReserve, (10 ** Decimals)),
        multipleWithDecimal(coinCAmountReserve, (10 ** Decimals)),
      )
    }

    const payload = {
      type: "entry_function_payload",
      function: `${CONFIG.moduleAddress}::${PackageName}::${pairType}`,
      type_arguments: typeArguments,
      // exchange_rate, coin_a_amount, coin_b_amount
      arguments: args,
    }
    try {
      const tx = await signAndSubmitTransaction(payload)
      await client.waitForTransactionWithResult(tx.hash)
      await apolloClient.refetchQueries({ include: [CoinBalancesQuery]})
      getAllTradingPairs()
      // reset form
      setFromCoinsSelected([])
      setToCoinsSelected([])
      setExchangeRateCoinA("")
    } catch (e) {
      console.log("ERROR during create new trading pair tx")
      console.log(e)
    }
  }

  const handleFromCoinChange = (coins: Array<string>) => {
    setFromCoinsSelected(coins)

    if (coins.length > 0) {
      const newToCoinsList = coinBalances.filter((coinBalance) => !coins.includes(coinBalance.coin_type))
      setToCoinsList(newToCoinsList)
    }
  }

  const handleToCoinChange = (coins: Array<string>) => {
    setToCoinsSelected(coins)
    
    if (coins.length > 0) {
      const newFromCoinsList = coinBalances.filter((coinBalance) => !coins.includes(coinBalance.coin_type))
      setFromCoinsList(newFromCoinsList)
    }
  }

  return (
    <Form form={form} className="create-pair-form" {...layout}>
      <Form.Item label="From Coin/coins:">
        <Select
          mode="multiple"
          placeholder="Select From Coin/Coin's"
          value={fromCoinsSelected}
          onChange={handleFromCoinChange}
          optionLabelProp="label"
          labelInValue={false}
        >
          {fromCoinsList.length > 0 && fromCoinsList.map((coinData) => (
            <Option
              value={coinData.coin_type}
              key={coinData.coin_type}
              label={<span>{coinData.coin_info.name}</span>}
            >
              <span>{coinData.coin_info.name} ({coinData.coin_info.symbol})</span>
            </Option>
          ))}
        </Select>
      </Form.Item>
      <Form.Item label="To Coin/coins:">
      <Select
          mode="multiple"
          placeholder="Select To Coin/Coin's"
          value={toCoinsSelected}
          onChange={handleToCoinChange}
          optionLabelProp="label"
          labelInValue={false}
        >
          {toCoinsList.length > 0 && toCoinsList.map((coinData) => (
            <Option
              value={coinData.coin_type}
              key={coinData.coin_type}
              label={<span>{coinData.coin_info.name}</span>}
            >
              <span>{coinData.coin_info.name} ({coinData.coin_info.symbol})</span>
            </Option>
          ))}
        </Select>
      </Form.Item>
      <Form.Item label={`Amount of coins ${formatCoinName(fromCoinsSelected[0])}`}>
        <Input
          type="number"
          value={coinAAmountReserve}
          onChange={(e) => setCoinAAmountReserve(Number(e.target.value))}
          placeholder="Amount of coins From moved to reserve"
        />
      </Form.Item>
      {fromCoinsSelected.length === 2 && (
        <Form.Item label={`Amount of coins ${formatCoinName(fromCoinsSelected[1])}`}>
          <Input
            type="number"
            value={coinBAmountReserve}
            onChange={(e) => setCoinBAmountReserve(Number(e.target.value))}
            placeholder="Amount of coins From moved to reserve"
          />
        </Form.Item>
      )}
      <Form.Item label={`Amount of coins ${formatCoinName(toCoinsSelected[0])}`}>
        <Input
          type="number"
          value={coinCAmountReserve}
          onChange={(e) => setCoinCAmountReserve(Number(e.target.value))}
          placeholder="Amount of coins To moved to reserve"
        />
      </Form.Item>
      {toCoinsSelected.length === 2 && (
        <Form.Item label={`Amount of coins ${formatCoinName(toCoinsSelected[1])}`}>
          <Input
            type="number"
            value={coinDAmountReserve}
            onChange={(e) => setCoinDAmountReserve(Number(e.target.value))}
            placeholder="Amount of coins From moved to reserve"
          />
        </Form.Item>
      )}
      <Form.Item label={`Exchange rate for ${formatCoinName(toCoinsSelected[0])}`}>
        <Input
          type="number"
          value={exchangeRateCoinA}
          onChange={(e) => setExchangeRateCoinA(e.target.value)}
          placeholder="Set exchange rate"
        />
      </Form.Item>
      {toCoinsSelected.length === 2 && fromCoinsSelected.length === 2 && (
        <Form.Item label={`Exchange rate for ${formatCoinName(toCoinsSelected[1])}`}>
          <Input
            type="number"
            value={exchangeRateCoinB}
            onChange={(e) => setExchangeRateCoinB(e.target.value)}
            placeholder="Set exchange rate"
            />
        </Form.Item>
      )}
        {/* basic trading pair */}
        {(exchangeRateCoinA && fromCoinsSelected.length === 1 && toCoinsSelected.length === 1) && (
          <div className="swap-calculation-container">
            <span>{`Estimation: 100 ${formatCoinName(fromCoinsSelected[0])} -> ${multipleWithDecimal(exchangeRateCoinA)} ${formatCoinName(toCoinsSelected[0])} `}</span>
          </div>
        )}
        {/* triple trading pair */}
        {/* 100 Crystal + 100 Gasolium = 150 Hypersteel */}
        {(exchangeRateCoinA && fromCoinsSelected.length === 2 && toCoinsSelected.length === 1) && (
          <div className="swap-calculation-container">
            <span>{`Estimation: 100 ${formatCoinName(fromCoinsSelected[0])} and 100 ${formatCoinName(fromCoinsSelected[1])} -> ${multipleWithDecimal(exchangeRateCoinA)} ${formatCoinName(toCoinsSelected[0])} `}</span>
          </div>
        )}
        {/* quadruple trading pair */}
        {/* 100 Crystal + 100 Gasolium = 2 Biomass + 3 Hypersteel */}
        {(exchangeRateCoinA && fromCoinsSelected.length === 2 && toCoinsSelected.length === 2 && exchangeRateCoinB) && (
          <div className="swap-calculation-container">
            <span>{`Estimation: 100
              ${formatCoinName(fromCoinsSelected[0])} and 100 ${formatCoinName(fromCoinsSelected[1])} 
              -> ${multipleWithDecimal(exchangeRateCoinA)} ${formatCoinName(toCoinsSelected[0])} and ${multipleWithDecimal(exchangeRateCoinB)} ${formatCoinName(toCoinsSelected[1])}`} 
            </span>
          </div>
        )}
      <Form.Item style={{ marginTop: '2rem', display: 'flex', justifyContent: 'center'}}>
        <Button onClick={onCreatePair} type="primary">Create Trading Pair</Button>
      </Form.Item>
    </Form>
  )
}
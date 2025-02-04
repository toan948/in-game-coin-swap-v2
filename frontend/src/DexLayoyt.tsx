import React, { useEffect, useState } from 'react'
import { Input, Row, Button, Col, Modal, Form, Switch } from 'antd'
import { useWallet } from '@aptos-labs/wallet-adapter-react'
import { WalletSelector } from "@aptos-labs/wallet-adapter-ant-design"
import { AptosClient, Provider, Network } from "aptos"
import { useApolloClient } from "@apollo/client"
import Decimal from "decimal.js"

import { CoinBalancesQuery } from './components/CoinBalance'
import { SwapEventsTable } from './components/SwapEventsTable'
import AllPairsTable from './components/AllPairsTable'
import { formatCoinName, multipleWithDecimal, CreatePairForm } from './components/CreatePairForm'
import CONFIG from "./config.json"

const PackageName = "swap_coins"

const DevnetClientUrl = "https://fullnode.devnet.aptoslabs.com/v1"
const TestnetClientUrl = "https://fullnode.testnet.aptoslabs.com"

const client = new AptosClient(CONFIG.network === "devnet" ? DevnetClientUrl : TestnetClientUrl)
const provider = new Provider(CONFIG.network === "devnet" ?  Network.DEVNET : Network.TESTNET);

const Decimals = 8


const DexLayoyt = () => {
  const { account, signAndSubmitTransaction } = useWallet()
  const apolloClient = useApolloClient()

  // Toggle admin panel
  const [showBlock, setShowBlock] = useState(false);
  const toggleBlock = (checked: boolean) => {
    setShowBlock(checked);
  };

  const [coinFromAmount, setCoinFromAmount] = useState<string>("0")
  const [coinToAmount1, setCoinToAmount1] = useState<string>("0")
  const [coinToAmount2, setCoinToAmount2] = useState<number>(0)


  // events
  const [selectedPairData, onSelectedPairData] = useState<any>(null)
  const [swapEvents, setSwapEvents] = useState<Array<any>>([])

  const [tradingPairs, setTradingPairs] = useState([])
  const [isIncreaseReservesVisible, setIsIncreaseReservesVisible] = useState(false)

  // reserves
  const [coinAAmountReserve, setCoinAAmountReserve] = useState(0)
  const [coinBAmountReserve, setCoinBAmountReserve] = useState(0)
  const [coinCAmountReserve, setCoinCAmountReserve] = useState(0)
  const [coinDAmountReserve, setCoinDAmountReserve] = useState(0)

  const onRemovePair = async (coinsFrom: Array<string>, coinsTo: Array<string>, pairId: string) => {
    const typeArguments: Array<any> = []
    coinsFrom.forEach((coinFrom) => typeArguments.push(coinFrom))
    coinsTo.forEach((coinTo) => typeArguments.push(coinTo))
    
    let pairType = "remove_pair"
    
    if (coinsFrom.length === 2 && coinsTo.length === 2) {
      pairType = "remove_quadruple_pair"
    } else if (coinsFrom.length === 2 && coinsTo.length === 1) {
      pairType = "remove_triple_pair"
    }

    const payload = {
      type: "entry_function_payload",
      function: `${CONFIG.moduleAddress}::${PackageName}::${pairType}`,
      type_arguments: typeArguments,
      arguments: [pairId],
    }
    try {
      const tx = await signAndSubmitTransaction(payload)
      await client.waitForTransactionWithResult(tx.hash)
      await apolloClient.refetchQueries({ include: [CoinBalancesQuery]})
      getAllTradingPairs()
    } catch (e) {
      console.log(`Error during ${pairType} tx`)
      console.log(e)
    }
  }


  const onSwap = async () => {
    if (!selectedPairData) {
      alert("Select one of the pairs please")
      return
    }

    let pairType = "swap"
    const typeArguments: Array<string> = [selectedPairData.value.coins_from_name[0]]
    const args: Array<String | number> = [selectedPairData.key, multipleWithDecimal(10 ** Decimals, coinFromAmount)]

    
    if (selectedPairData.value.coins_from_name.length === 2 && selectedPairData.value.coins_to_name.length === 1) {
      pairType = "triple_swap"
      args.push(multipleWithDecimal(10 ** Decimals, coinFromAmount))
      typeArguments.push(selectedPairData.value.coins_from_name[1], selectedPairData.value.coins_to_name[0])
    } else if (selectedPairData.value.coins_from_name.length === 2 && selectedPairData.value.coins_to_name.length === 2) {
      pairType = "quadruple_swap"
      args.push(multipleWithDecimal(10 ** Decimals, coinFromAmount))
      typeArguments.push(selectedPairData.value.coins_from_name[1], selectedPairData.value.coins_to_name[0], selectedPairData.value.coins_to_name[1])
    } else {
      typeArguments.push(selectedPairData.value.coins_to_name[0])
    }

    const payload = {
      type: "entry_function_payload",
      function: `${CONFIG.moduleAddress}::${PackageName}::${pairType}`,
      type_arguments: typeArguments,
      //            basic swap   triple or quadruple          
      // pair_id, coin_amount_a / coin_amount_b
      arguments: args,
    }
    try {
      const tx = await signAndSubmitTransaction(payload)
      await client.waitForTransactionWithResult(tx.hash)
      await apolloClient.refetchQueries({ include: [CoinBalancesQuery]})
      setCoinFromAmount("0")
      setCoinToAmount1("0")
      setCoinToAmount2(0)
    } catch (e) {
      console.log("Error during swap coins tx")
      console.log(e)
    }
  }

  const onIncreaseReserves = async () => {
    if (!coinAAmountReserve || !coinBAmountReserve) {
      alert("Put some value in inputs")
      return
    }

    let pairType = "increase_reserves"
    const typeArguments: Array<string> = [selectedPairData.value.coins_from_name[0]]
    const args = [selectedPairData.key, multipleWithDecimal(10 ** Decimals, coinAAmountReserve)]

    if (selectedPairData.value.coins_from_name.length === 2 && selectedPairData.value.coins_to_name.length === 1) {
      pairType = "increase_triple_reserves"
      args.push(
        multipleWithDecimal(10 ** Decimals, coinBAmountReserve),
        multipleWithDecimal(10 ** Decimals, coinCAmountReserve),
      )
      typeArguments.push(selectedPairData.value.coins_from_name[1], selectedPairData.value.coins_to_name[0])
    } else if (selectedPairData.value.coins_from_name.length === 2 && selectedPairData.value.coins_to_name.length === 2) {
      pairType = "increase_quadruple_reserves"
      args.push(
        multipleWithDecimal(10 ** Decimals, coinBAmountReserve),
        multipleWithDecimal(10 ** Decimals, coinCAmountReserve),
        multipleWithDecimal(10 ** Decimals, coinDAmountReserve),
      )
      typeArguments.push(selectedPairData.value.coins_from_name[1], selectedPairData.value.coins_to_name[0], selectedPairData.value.coins_to_name[1])
    } else {
      args.push(multipleWithDecimal(10 ** Decimals, coinCAmountReserve))
      typeArguments.push(selectedPairData.value.coins_to_name[0])
    }

    const payload = {
      type: "entry_function_payload",
      function: `${CONFIG.moduleAddress}::${PackageName}::${pairType}`,
      type_arguments: typeArguments,
      arguments: args,
    }
    try {
      const tx = await signAndSubmitTransaction(payload)
      await client.waitForTransactionWithResult(tx.hash)
      await apolloClient.refetchQueries({ include: [CoinBalancesQuery]})
      setCoinAAmountReserve(0)
      setCoinBAmountReserve(0)
      setCoinCAmountReserve(0)
      setCoinDAmountReserve(0)
      setIsIncreaseReservesVisible(false)
    } catch (e) {
      console.log("Error during swap coins tx")
      console.log(e)
    }
  }

  // get list of all pairs
  const getAllTradingPairs = async () => {
    const payload = {
      function: `${CONFIG.moduleAddress}::${PackageName}::get_all_pairs`,
      type_arguments: [],
      arguments: []
    }

    try {
      const allPairsResponse: any = await provider.view(payload)
      setTradingPairs(allPairsResponse[0].data)
    } catch(e) {
      console.log("Error during getting unclaimed")
      console.log(e)
    }
  }

  useEffect(() => {
    if (account?.address) {
      getAllTradingPairs()
      getSwapEvents()
    }
  }, [account?.address])

  const getSwapEvents = async () => {
    const eventsStore = `${CONFIG.moduleAddress}::${PackageName}::Events`

    try {
      const eventsResult = await client.getEventsByEventHandle(CONFIG.moduleAddress, eventsStore, "swap_event")
      const formattedSwapEvents = eventsResult.map((event) => ({
        id: event.guid.account_address + event.guid.creation_number,
        ...event.data,
      }))
      setSwapEvents(formattedSwapEvents)
    } catch (e: any) {
      console.log(e)
      const errorMessage = JSON.parse(e.message)
      if (errorMessage.error_code === "resource_not_found") {
        console.log("No swaps for now")
      }
    }
  }

  useEffect(() => {
    if (coinFromAmount && selectedPairData) {
      setCoinToAmount1(Number(multipleWithDecimal(selectedPairData.value.exchange_rates[0], Number(coinFromAmount))) / 100 as any)
      if (selectedPairData.value.exchange_rates[1]) {
        setCoinToAmount2(Number(multipleWithDecimal(selectedPairData.value.exchange_rates[1], Number(coinFromAmount))) / 100)
      }
    }
  }, [coinFromAmount, selectedPairData])

  useEffect(() => {
    setCoinFromAmount("0")
    setCoinToAmount1("0")
    setCoinToAmount2(0)
  }, [selectedPairData])

  return (
    <>
      <Row>
        <div className="dex">
          <h2>Trading post</h2>
          <div className="swaps-container">
            {/* Swap from Coins */}
            <div className="swap-from">
              <div className="first-coin">
                {selectedPairData && <p className='coin-name'>{formatCoinName(selectedPairData.value.coins_from_name[0])}</p>}
                <Input
                  type="number"
                  value={coinFromAmount}
                  onChange={(e) => {
                    if (!e.target.value) {
                      return setCoinFromAmount('')
                    }
                    setCoinFromAmount(new Decimal(e.target.value).toString())
                  }}
                />
              </div>
              {selectedPairData && selectedPairData?.value?.coins_from_name.length === 2 && (
                <div className="second-coin">
                  <p className='coin-name'>{formatCoinName(selectedPairData.value.coins_from_name[1])}</p>
                  <Input
                    type="number"
                    value={coinFromAmount}
                    onChange={(e) => {
                      setCoinFromAmount(new Decimal(e.target.value).toString())
                    }}
                  />
                </div>
              )}
            </div>
            <div className="arrow-right-container">
              <img src="../icons/right-arrow.png" alt="arrow-right" />
            </div>
            {/* Swap to Coins*/}
            <div className="swap-to">
              <div className="first-coin">
                {selectedPairData && <p className='coin-name'>{formatCoinName(selectedPairData.value.coins_to_name[0])}</p>}
                <Input type="number" value={coinToAmount1} />
              </div>
              {selectedPairData && selectedPairData?.value?.coins_from_name.length === 2 && selectedPairData?.value?.coins_to_name.length === 2 && (
                <div className="second-coin">
                  <p className='coin-name'>{formatCoinName(selectedPairData.value.coins_to_name[1])}</p>
                  <Input value={coinToAmount2} type="number" />
                </div>
              )}
            </div>
          </div>
          <div className="swap-button">
            {account?.address ? (
              <Button
                style={{ height: '2.5rem'}}
                onClick={onSwap}
                block
                type="primary"
              >
                Swap
              </Button>
            ) : (
              <WalletSelector />
            )}
          </div>
        </div>
      </Row>
      <Col className='admin-switch'>
        <span className='show-admin-panel'>Show admin panel</span>
        <Switch checked={showBlock} onChange={toggleBlock} />
      </Col>
      {showBlock && (
        <div>
          <Col>
            <AllPairsTable
              data={tradingPairs}
              onRemovePair={onRemovePair}
              onSelectedPairData={onSelectedPairData}
              openReservesModal={() => setIsIncreaseReservesVisible(true)}
            />
          </Col>
          <Col>
            <CreatePairForm getAllTradingPairs={getAllTradingPairs} />
          </Col>
          <Col>
            <SwapEventsTable data={swapEvents} />
          </Col>
          <Modal
            title="Increase reserves"
            open={isIncreaseReservesVisible && selectedPairData}
            onCancel={() => setIsIncreaseReservesVisible(false)}
            onOk={onIncreaseReserves}
            okText="Increase"
          >
            <Form className="increase-reserves-form">
              <Form.Item label={`Amount of coins ${formatCoinName(selectedPairData?.value?.coins_from_name[0])}`}>
                <Input
                  type="number"
                  value={coinAAmountReserve}
                  onChange={(e) => setCoinAAmountReserve(Number(e.target.value))}
                  placeholder="Amount of coins From moved to reserve"
                />
              </Form.Item>
              <Form.Item label={`Amount of coins ${formatCoinName(selectedPairData?.value?.coins_to_name[0])}`}>
                <Input
                  type="number"
                  value={coinCAmountReserve}
                  onChange={(e) => setCoinCAmountReserve(Number(e.target.value))}
                  placeholder="Amount of coins From moved to reserve"
                />
              </Form.Item>
              {selectedPairData && selectedPairData?.value?.coins_from_name.length === 2 && (
                <Form.Item label={`Amount of coins ${formatCoinName(selectedPairData?.value?.coins_from_name[1])}`}>
                  <Input
                    type="number"
                    value={coinBAmountReserve}
                    onChange={(e) => setCoinBAmountReserve(Number(e.target.value))}
                    placeholder="Amount of coins From moved to reserve"
                  />
                </Form.Item>
              )}
              {selectedPairData && selectedPairData?.value?.coins_from_name.length === 2 && selectedPairData?.value?.coins_to_name.length === 2 && (
                <Form.Item label={`Amount of coins ${formatCoinName(selectedPairData?.value?.coins_to_name[1])}`}>
                  <Input
                    type="number"
                    value={coinDAmountReserve}
                    onChange={(e) => setCoinDAmountReserve(Number(e.target.value))}
                    placeholder="Amount of coins From moved to reserve"
                  />
                </Form.Item>
              )}
            </Form>
          </Modal>
        </div>
      )}
    </>
  )
}

export default DexLayoyt
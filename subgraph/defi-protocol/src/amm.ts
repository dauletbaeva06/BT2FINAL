import {
  Swap as SwapEvent,
  LiquidityAdded as LiquidityAddedEvent
} from "../generated/AMM/AMM";

import {
  Swap,
  LiquidityAdded
} from "../generated/schema";

export function handleSwap(event: SwapEvent): void {
  let entity = new Swap(
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  );

  entity.trader = event.params.trader;
  entity.tokenIn = event.params.tokenIn;
  entity.tokenOut = event.params.tokenOut;
  entity.amountIn = event.params.amountIn;
  entity.amountOut = event.params.amountOut;
  entity.fee = event.params.fee;
  entity.timestamp = event.params.timestamp;

  entity.save();
}

export function handleLiquidityAdded(event: LiquidityAddedEvent): void {
  let entity = new LiquidityAdded(
    event.transaction.hash.toHexString() + "-" + event.logIndex.toString()
  );

  entity.provider = event.params.provider;
  entity.amount0 = event.params.amount0;
  entity.amount1 = event.params.amount1;
  entity.lpTokensMinted = event.params.lpTokensMinted;
  entity.timestamp = event.params.timestamp;

  entity.save();
}
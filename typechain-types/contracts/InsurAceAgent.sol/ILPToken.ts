/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumber,
  BigNumberish,
  BytesLike,
  CallOverrides,
  ContractTransaction,
  Overrides,
  PopulatedTransaction,
  Signer,
  utils,
} from "ethers";
import type { FunctionFragment, Result } from "@ethersproject/abi";
import type { Listener, Provider } from "@ethersproject/providers";
import type {
  TypedEventFilter,
  TypedEvent,
  TypedListener,
  OnEvent,
  PromiseOrValue,
} from "../../common";

export interface ILPTokenInterface extends utils.Interface {
  functions: {
    "burn(address,uint256,uint256)": FunctionFragment;
    "burnableAmtOf(address)": FunctionFragment;
    "mint(address,uint256,uint256)": FunctionFragment;
    "pendingBurnAmtPH(address)": FunctionFragment;
    "proposeToBurn(address,uint256,uint256)": FunctionFragment;
    "rewardDebtOf(address)": FunctionFragment;
  };

  getFunction(
    nameOrSignatureOrTopic:
      | "burn"
      | "burnableAmtOf"
      | "mint"
      | "pendingBurnAmtPH"
      | "proposeToBurn"
      | "rewardDebtOf"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "burn",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "burnableAmtOf",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "mint",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "pendingBurnAmtPH",
    values: [PromiseOrValue<string>]
  ): string;
  encodeFunctionData(
    functionFragment: "proposeToBurn",
    values: [
      PromiseOrValue<string>,
      PromiseOrValue<BigNumberish>,
      PromiseOrValue<BigNumberish>
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "rewardDebtOf",
    values: [PromiseOrValue<string>]
  ): string;

  decodeFunctionResult(functionFragment: "burn", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "burnableAmtOf",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "mint", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "pendingBurnAmtPH",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "proposeToBurn",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "rewardDebtOf",
    data: BytesLike
  ): Result;

  events: {};
}

export interface ILPToken extends BaseContract {
  connect(signerOrProvider: Signer | Provider | string): this;
  attach(addressOrName: string): this;
  deployed(): Promise<this>;

  interface: ILPTokenInterface;

  queryFilter<TEvent extends TypedEvent>(
    event: TypedEventFilter<TEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TEvent>>;

  listeners<TEvent extends TypedEvent>(
    eventFilter?: TypedEventFilter<TEvent>
  ): Array<TypedListener<TEvent>>;
  listeners(eventName?: string): Array<Listener>;
  removeAllListeners<TEvent extends TypedEvent>(
    eventFilter: TypedEventFilter<TEvent>
  ): this;
  removeAllListeners(eventName?: string): this;
  off: OnEvent<this>;
  on: OnEvent<this>;
  once: OnEvent<this>;
  removeListener: OnEvent<this>;

  functions: {
    burn(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    burnableAmtOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    mint(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    pendingBurnAmtPH(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;

    proposeToBurn(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _blockWeight: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<ContractTransaction>;

    rewardDebtOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<[BigNumber]>;
  };

  burn(
    _account: PromiseOrValue<string>,
    _amount: PromiseOrValue<BigNumberish>,
    _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  burnableAmtOf(
    _account: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  mint(
    _account: PromiseOrValue<string>,
    _amount: PromiseOrValue<BigNumberish>,
    _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  pendingBurnAmtPH(
    arg0: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  proposeToBurn(
    _account: PromiseOrValue<string>,
    _amount: PromiseOrValue<BigNumberish>,
    _blockWeight: PromiseOrValue<BigNumberish>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<ContractTransaction>;

  rewardDebtOf(
    _account: PromiseOrValue<string>,
    overrides?: CallOverrides
  ): Promise<BigNumber>;

  callStatic: {
    burn(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    burnableAmtOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    mint(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    pendingBurnAmtPH(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    proposeToBurn(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _blockWeight: PromiseOrValue<BigNumberish>,
      overrides?: CallOverrides
    ): Promise<void>;

    rewardDebtOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  filters: {};

  estimateGas: {
    burn(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    burnableAmtOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    mint(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    pendingBurnAmtPH(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;

    proposeToBurn(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _blockWeight: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<BigNumber>;

    rewardDebtOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<BigNumber>;
  };

  populateTransaction: {
    burn(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    burnableAmtOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    mint(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _poolRewardPerLPToken: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    pendingBurnAmtPH(
      arg0: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;

    proposeToBurn(
      _account: PromiseOrValue<string>,
      _amount: PromiseOrValue<BigNumberish>,
      _blockWeight: PromiseOrValue<BigNumberish>,
      overrides?: Overrides & { from?: PromiseOrValue<string> }
    ): Promise<PopulatedTransaction>;

    rewardDebtOf(
      _account: PromiseOrValue<string>,
      overrides?: CallOverrides
    ): Promise<PopulatedTransaction>;
  };
}

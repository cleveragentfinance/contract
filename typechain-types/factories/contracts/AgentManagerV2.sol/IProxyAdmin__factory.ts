/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import type { Provider } from "@ethersproject/providers";
import type {
  IProxyAdmin,
  IProxyAdminInterface,
} from "../../../contracts/AgentManagerV2.sol/IProxyAdmin";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    name: "upgrade",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export class IProxyAdmin__factory {
  static readonly abi = _abi;
  static createInterface(): IProxyAdminInterface {
    return new utils.Interface(_abi) as IProxyAdminInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IProxyAdmin {
    return new Contract(address, _abi, signerOrProvider) as IProxyAdmin;
  }
}
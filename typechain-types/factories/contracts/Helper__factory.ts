/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../common";
import type { Helper, HelperInterface } from "../../contracts/Helper";

const _abi = [
  {
    inputs: [
      {
        internalType: "contract IAgentManager",
        name: "_manager",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "previousOwner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "OwnershipTransferred",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_user",
        type: "address",
      },
    ],
    name: "getAvailableTicket",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_from",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "_to",
        type: "uint256",
      },
    ],
    name: "getMultiplier",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "manager",
    outputs: [
      {
        internalType: "contract IAgentManager",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "owner",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "renounceOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "newOwner",
        type: "address",
      },
    ],
    name: "transferOwnership",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b506040516107a93803806107a983398101604081905261002f916100ad565b6100383361005d565b600180546001600160a01b0319166001600160a01b03929092169190911790556100db565b600080546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b6000602082840312156100be578081fd5b81516001600160a01b03811681146100d4578182fd5b9392505050565b6106bf806100ea6000396000f3fe608060405234801561001057600080fd5b50600436106100625760003560e01c8063481c6a7514610067578063715018a6146100975780638da5cb5b146100a15780638dbb1e3a146100b2578063f2fde38b146100d3578063f7579efb146100e6575b600080fd5b60015461007a906001600160a01b031681565b6040516001600160a01b0390911681526020015b60405180910390f35b61009f6100f9565b005b6000546001600160a01b031661007a565b6100c56100c03660046105c9565b61010d565b60405190815260200161008e565b61009f6100e136600461050f565b6101af565b6100c56100f436600461050f565b61022d565b610101610441565b61010b600061049b565b565b60006101a8600160009054906101000a90046001600160a01b03166001600160a01b0316638aa285506040518163ffffffff1660e01b815260040160206040518083038186803b15801561016057600080fd5b505afa158015610174573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061019891906105b1565b6101a284866104eb565b906104f7565b9392505050565b6101b7610441565b6001600160a01b0381166102215760405162461bcd60e51b815260206004820152602660248201527f4f776e61626c653a206e6577206f776e657220697320746865207a65726f206160448201526564647265737360d01b60648201526084015b60405180910390fd5b61022a8161049b565b50565b600080805b600160009054906101000a90046001600160a01b03166001600160a01b031663081e3eda6040518163ffffffff1660e01b815260040160206040518083038186803b15801561028057600080fd5b505afa158015610294573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102b891906105b1565b81101561043a576001546040516393f1a40b60e01b8152600481018390526001600160a01b03868116602483015260009216906393f1a40b9060440160a06040518083038186803b15801561030c57600080fd5b505afa158015610320573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103449190610536565b9050600061035682608001514261010d565b90506000610404670de0b6b3a76400006103fe85600001516101a2600160009054906101000a90046001600160a01b03166001600160a01b0316633bcfc4b86040518163ffffffff1660e01b815260040160206040518083038186803b1580156103bf57600080fd5b505afa1580156103d3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906103f791906105b1565b87906104f7565b90610503565b905082606001518561041691906105ea565b945061042281866105ea565b9450505050808061043290610658565b915050610232565b5092915050565b6000546001600160a01b0316331461010b5760405162461bcd60e51b815260206004820181905260248201527f4f776e61626c653a2063616c6c6572206973206e6f7420746865206f776e65726044820152606401610218565b600080546001600160a01b038381166001600160a01b0319831681178455604051919092169283917f8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e09190a35050565b60006101a88284610641565b60006101a88284610622565b60006101a88284610602565b600060208284031215610520578081fd5b81356001600160a01b03811681146101a8578182fd5b600060a08284031215610547578081fd5b60405160a0810181811067ffffffffffffffff8211171561057657634e487b7160e01b83526041600452602483fd5b806040525082518152602083015160208201526040830151604082015260608301516060820152608083015160808201528091505092915050565b6000602082840312156105c2578081fd5b5051919050565b600080604083850312156105db578081fd5b50508035926020909101359150565b600082198211156105fd576105fd610673565b500190565b60008261061d57634e487b7160e01b81526012600452602481fd5b500490565b600081600019048311821515161561063c5761063c610673565b500290565b60008282101561065357610653610673565b500390565b600060001982141561066c5761066c610673565b5060010190565b634e487b7160e01b600052601160045260246000fdfea2646970667358221220cd61696a4a90bfb8016eefe416d13eeb0dab11485505d84f365b13a34c314ec664736f6c63430008040033";

type HelperConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: HelperConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class Helper__factory extends ContractFactory {
  constructor(...args: HelperConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    _manager: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<Helper> {
    return super.deploy(_manager, overrides || {}) as Promise<Helper>;
  }
  override getDeployTransaction(
    _manager: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(_manager, overrides || {});
  }
  override attach(address: string): Helper {
    return super.attach(address) as Helper;
  }
  override connect(signer: Signer): Helper__factory {
    return super.connect(signer) as Helper__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): HelperInterface {
    return new utils.Interface(_abi) as HelperInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Helper {
    return new Contract(address, _abi, signerOrProvider) as Helper;
  }
}

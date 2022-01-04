// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.10;

import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {Errors} from '../libraries/helpers/Errors.sol';
import {IPoolAddressesProviderRegistry} from '../../interfaces/IPoolAddressesProviderRegistry.sol';

/**
 * @title PoolAddressesProviderRegistry
 * @author Aave
 * @notice Main registry of PoolAddressesProvider of Aave markets.
 * @dev Used for indexing purposes of Aave protocol's markets. The id assigned
 *   to a PoolAddressesProvider refers to the market it is connected with, for
 *   example with `1` for the Aave main market and `2` for the next created.
 **/
contract PoolAddressesProviderRegistry is Ownable, IPoolAddressesProviderRegistry {
  mapping(address => uint256) private _addressesProviders;
  address[] private _addressesProvidersList;

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProvidersList() external view override returns (address[] memory) {
    uint256 providersListCount = _addressesProvidersList.length;
    uint256 removedProvidersCount = 0;

    address[] memory providers = new address[](providersListCount);

    for (uint256 i = 0; i < providersListCount; i++) {
      if (_addressesProviders[_addressesProvidersList[i]] > 0) {
        providers[i - removedProvidersCount] = _addressesProvidersList[i];
      } else {
        removedProvidersCount++;
      }
    }

    // Reduces the length of the providers array by `removedProvidersCount`
    assembly {
      mstore(providers, sub(providersListCount, removedProvidersCount))
    }
    return providers;
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function registerAddressesProvider(address provider, uint256 id) external override onlyOwner {
    require(id != 0, Errors.INVALID_ADDRESSES_PROVIDER_ID);

    _addressesProviders[provider] = id;
    _addToAddressesProvidersList(provider);
    emit AddressesProviderRegistered(provider, id);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function unregisterAddressesProvider(address provider) external override onlyOwner {
    require(_addressesProviders[provider] > 0, Errors.PROVIDER_NOT_REGISTERED);
    uint256 id = _addressesProviders[provider];
    _addressesProviders[provider] = 0;
    emit AddressesProviderUnregistered(provider, id);
  }

  /// @inheritdoc IPoolAddressesProviderRegistry
  function getAddressesProviderIdByAddress(address addressesProvider)
    external
    view
    override
    returns (uint256)
  {
    return _addressesProviders[addressesProvider];
  }

  /**
   * @notice Adds the addresses provider address to the list.
   * @dev The addressesProvider must not already exists in the registry
   * @param provider The address of the PoolAddressesProvider
   */
  function _addToAddressesProvidersList(address provider) internal {
    uint256 providersCount = _addressesProvidersList.length;

    for (uint256 i = 0; i < providersCount; i++) {
      require(_addressesProvidersList[i] != provider, Errors.ADDRESSES_PROVIDER_ALREADY_ADDED);
    }

    _addressesProvidersList.push(provider);
  }
}

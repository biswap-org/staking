pragma solidity 0.6.12;
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            'SafeBEP20: approve from non-zero to non-zero allowance'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            'SafeBEP20: decreased allowance below zero'
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, 'SafeBEP20: low-level call failed');
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), 'SafeBEP20: BEP20 operation did not succeed');
        }
    }
}
import "./BSWToken.sol";

contract InvestorMine is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // The BSW TOKEN!
    BSWToken public BSW;

    //Investor, Dev, Refs percent decimals
    uint256 public percentDec = 1000000;
    //Investor percent from token per block
    uint256 public investorPercent;
    //Developers percent from token per block
    uint256 public devPercent;
    //Referrals percent from token per block
    uint256 public refPercent;
    //Safu fund percent from token per block
    uint256 public safuPercent;

    // Investor address.
    address public investoraddr;
    // Dev address.
    address public devaddr;
    // Safu fund.
    address public safuaddr;
    // Referrals commission address.
    address public refaddr;

    // Last block then developer withdraw dev, ref, investor
    uint256 public lastBlockWithdraw;
    // BSW tokens created per block.
    uint256 public BSWPerBlock;

    constructor(
        BSWToken _BSW,
        address _devaddr,
        address _refaddr,
        address _safuaddr,
        address _investoraddr,
        uint256 _BSWPerBlock,
        uint256 _startBlock
    ) public {
        BSW = _BSW;
        investoraddr = _investoraddr;
        devaddr = _devaddr;
        refaddr = _refaddr;
        safuaddr = _safuaddr;
        BSWPerBlock = _BSWPerBlock;
        lastBlockWithdraw = _startBlock;

        investorPercent = 857000;
        devPercent = 90000;
        refPercent = 43000;
        safuPercent = 10000;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from);
    }

    function withdraw() public{
        require(lastBlockWithdraw < block.number, 'wait for new block');
        uint256 multiplier = getMultiplier(lastBlockWithdraw, block.number);
        uint256 BSWReward = multiplier.mul(BSWPerBlock);
        BSW.mint(investoraddr, BSWReward.mul(investorPercent).div(percentDec));
        BSW.mint(devaddr, BSWReward.mul(devPercent).div(percentDec));
        BSW.mint(safuaddr, BSWReward.mul(safuPercent).div(percentDec));
        BSW.mint(refaddr, BSWReward.mul(refPercent).div(percentDec));
        lastBlockWithdraw = block.number;
    }

    // Safe BSW transfer function, just in case if rounding error causes pool to not have enough BSWs.
    function safeBSWTransfer(address _to, uint256 _amount) internal {
        uint256 BSWBal = BSW.balanceOf(address(this));
        if (_amount > BSWBal) {
            BSW.transfer(_to, BSWBal);
        } else {
            BSW.transfer(_to, _amount);
        }
    }

    function setNewAddresses(address _investoraddr, address _devaddr, address _refaddr, address _safuaddr) public onlyOwner {
        investoraddr = _investoraddr;
        devaddr = _devaddr;
        refaddr = _refaddr;
        safuaddr = _safuaddr;
    }

    function changePercents(uint256 _investor, uint256 _dev, uint256 _ref, uint256 _safu) public onlyOwner{
        investorPercent = _investor;
        devPercent = _dev;
        refPercent = _ref;
        safuPercent = _safu;
    }

    function updateBswPerBlock(uint256 newAmount) public onlyOwner {
        require(newAmount <= 10 * 1e18, 'Max per block 10 BSW');
        BSWPerBlock = newAmount;
    }

    function updateLastWithdrawBlock(uint256 _blockNumber) public onlyOwner {
        lastBlockWithdraw = _blockNumber;
    }
}
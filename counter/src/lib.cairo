#[starknet::contract]
mod erc20 {
    use starknet::contract_address::ContractAddress;
    use starknet::context::{get_caller_address, emit_event};
    use starknet::storage::Map;

    #[storage]
    struct Storage {
        balances: Map<ContractAddress, u256>,  
        total_supply: u256,                     
        allowances: Map<(ContractAddress, ContractAddress), u256>,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        let caller = get_caller_address();
        self.total_supply.write(1_000_000_u256);
        self.balances.write_unchecked(caller, 1_000_000_u256);
    }

    #[abi(embed_v0)]
    impl ERC20 {
        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.balances.read(account).unwrap_or(0_u256)
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn transfer(ref self: ContractState, to: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            let sender_balance = self.balances.read(caller).unwrap_or(0_u256);
            if sender_balance < amount { return false; }

            self._update_balance(caller, sender_balance - amount);
            self._update_balance(to, self.balances.read(to).unwrap_or(0_u256) + amount);

            emit_event!(Transfer { from: caller, to, value: amount });
            true
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            self.allowances.write((caller, spender), amount);
            emit_event!(Approval { owner: caller, spender, value: amount });
            true
        }

        fn transfer_from(ref self: ContractState, from: ContractAddress, to: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            let allowed_balance = self.allowances.read((from, caller)).unwrap_or(0_u256);
            if allowed_balance < amount { return false; }

            let from_balance = self.balances.read(from).unwrap_or(0_u256);
            if from_balance < amount { return false; }

            self._update_balance(from, from_balance - amount);
            self._update_balance(to, self.balances.read(to).unwrap_or(0_u256) + amount);

            self.allowances.write((from, caller), allowed_balance - amount);
            emit_event!(Transfer { from, to, value: amount });
            true
        }

        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.allowances.read((owner, spender)).unwrap_or(0_u256)
        }

        // Internal function to update balances
        fn _update_balance(ref self: ContractState, account: ContractAddress, new_balance: u256) {
            self.balances.write(account, new_balance);
        }
    }

    // Events for Transfer and Approval
    #[event]
    pub struct Transfer {
        pub from: ContractAddress,
        pub to: ContractAddress,
        pub value: u256,
    }

    #[event]
    pub struct Approval {
        pub owner: ContractAddress,
        pub spender: ContractAddress,
        pub value: u256,
    }
}

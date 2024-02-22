module my_first_package::my_module {

    // Part 1: Imports
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    #[test_only]
    use std::debug;
    #[test_only]
    use sui::test_utils::assert_eq;

    // Part 2: Struct definitions
    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
    }

    struct Forge has key, store {
        id: UID,
        swords_created: u64,
    }

    // Part 3: Module initializer to be executed when this module is published
    fun init(ctx: &mut TxContext) {
        let admin = Forge {
            id: object::new(ctx),
            swords_created: 0,
        };
        // Transfer the forge object to the module/package publisher
        transfer::transfer(admin, tx_context::sender(ctx));
    }

    // Part 4: Accessors required to read the struct attributes
    public fun magic(self: &Sword): u64 {
        self.magic
    }

    public fun strength(self: &Sword): u64 {
        self.strength
    }

    public fun swords_created(self: &Forge): u64 {
        self.swords_created
    }

    // Part 5: Public/entry functions (introduced later in the tutorial)
    public fun sword_create(
        forge: &mut Forge,
        magic: u64,
        strength: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        use sui::transfer;

        let sword = Sword {
            id: object::new(ctx),
            magic,
            strength,
        };

        forge.swords_created = forge.swords_created + 1;

        transfer::transfer(sword, recipient);
    }

    fun sword_transfer(sword: Sword, recipient: address, _ctx: &mut TxContext) {
        use sui::transfer;

        transfer::transfer(sword, recipient);
    }

    // Part 6: Private functions (if any)

    #[test]
    public fun test_sword_create() {
        use sui::transfer;

        let ctx = tx_context::dummy();

        let sword = Sword {
            id: object::new(&mut ctx),
            magic: 42,
            strength: 7,
        };

        assert!(magic(&sword) == 42, 1);
        assert!(strength(&sword) == 7, 1);

        let dummy_address = @0xCAFE;
        transfer::transfer(sword, dummy_address);
    }

    #[test]
    fun test_sword_transactions() {
        use sui::test_scenario;

        let admin = @0xBABE;
        let intial_owner = @0xCAFE;
        let final_owner = @0xFACE;

        let scenario_val = test_scenario::begin(admin);
        let scenario = &mut scenario_val;
        {
            init(test_scenario::ctx(scenario));
            debug::print(scenario);
        };

        test_scenario::next_tx(scenario, admin);
        {
            debug::print(scenario);
            let forge = test_scenario::take_from_sender<Forge>(scenario);
            sword_create(&mut forge, 42, 7, intial_owner, test_scenario::ctx(scenario));
            test_scenario::return_to_sender(scenario, forge);
        };

        test_scenario::next_tx(scenario, intial_owner);
        {
            debug::print(scenario);
            let sword = test_scenario::take_from_sender<Sword>(scenario);
            sword_transfer(sword, final_owner, test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, final_owner);
        {
            debug::print(scenario);
            let sword = test_scenario::take_from_sender<Sword>(scenario);

            assert_eq(magic(&sword), 42);
            assert_eq(strength(&sword), 7);

            test_scenario::return_to_sender(scenario, sword);
        };

        test_scenario::end(scenario_val);
    }

    #[test_only] use sui::test_scenario;
    #[test_only] const ADMIN: address = @0xAD;
    #[test]
    public fun test_module_init() {
        let ts = test_scenario::begin(@0x0);
        {
            test_scenario::next_tx(&mut ts, ADMIN);
            init(test_scenario::ctx(&mut ts));
        };

        {
            test_scenario::next_tx(&mut ts, ADMIN);

            let forge = test_scenario::take_from_sender<Forge>(&mut ts);

            assert_eq(swords_created(&forge), 0);

            test_scenario::return_to_sender(&mut ts, forge);
        };

        test_scenario::end(ts);
    }
}
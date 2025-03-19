module PhotographyNFT::NFTGallery {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_std::table::{Self, Table};

    /// Struct representing an NFT photograph
    struct PhotoNFT has store, key {
        price: u64,           // Price of the NFT in APT coins
        creator: address,     // Photographer who minted the NFT
        is_for_sale: bool     // Whether the NFT is available for purchase
    }

    /// Struct to store creator's NFT collection
    struct Gallery has key {
        nfts: Table<u64, PhotoNFT>,  // Maps token_id to PhotoNFT
        next_id: u64                // Counter for next available token ID
    }

    /// Function for photographers to mint a new NFT photograph
    public entry fun mint_photo_nft(creator: &signer, price: u64) acquires Gallery {
        let creator_addr = signer::address_of(creator);
        
        // Initialize Gallery if it doesn't exist
        if (!exists<Gallery>(creator_addr)) {
            move_to(creator, Gallery {
                nfts: table::new(),
                next_id: 0
            });
        };

        let gallery = borrow_global_mut<Gallery>(creator_addr);
        let token_id = gallery.next_id;
        
        // Create and store the new NFT
        let nft = PhotoNFT {
            price,
            creator: creator_addr,
            is_for_sale: true
        };
        table::add(&mut gallery.nfts, token_id, nft);
        gallery.next_id = token_id + 1;
    }

    /// Function for buyers to purchase an NFT photograph
    public entry fun buy_photo_nft(buyer: &signer, creator: address, token_id: u64) acquires Gallery {
        let gallery = borrow_global_mut<Gallery>(creator);
        let nft = table::borrow_mut(&mut gallery.nfts, token_id);
        
        assert!(nft.is_for_sale, 100);  // Ensure NFT is for sale
        
        // Transfer payment from buyer to creator
        let payment = coin::withdraw<AptosCoin>(buyer, nft.price);
        coin::deposit<AptosCoin>(creator, payment);
        
        // Update NFT status
        nft.is_for_sale = false;
    }
}

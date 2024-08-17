import { useReadContract, useWriteContract } from "wagmi";
import { adminAbi } from "../../abis/adminAbi";
import { NFTAbi } from "../../abis/NFTAbi";
import { useState } from "react";
import { TokenAbi } from "../../abis/TokenAbi";

const adminAddress = '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';
const NFTAddress = '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9';
const TokenAddress = '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512';
const USDTAddress = '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0';

function Buy() {
    
    const { writeContract } = useWriteContract();
    const [tokenId,setTokenId] = useState('');

    function handleBuy() {

        const _tokenId = BigInt(tokenId);
        
        writeContract({
            abi: adminAbi,
            address: adminAddress,
            functionName: 'buy',
            args: [_tokenId],
        })

    }

    return (
        <div>
            <h1>Buy</h1>
            <input
                type="text"
                placeholder='Enter TokenId'
                value={tokenId}
                onChange={(e) => setTokenId(e.target.value)}
            />
            <button onClick={handleBuy}>buy</button>
        </div>
    )

}

function Rent() {

    const { writeContract } = useWriteContract();
    const [tokenId,setTokenId] = useState('');

    function handleRent() {
        
        const _tokenId = BigInt(tokenId);

        writeContract({
            abi: adminAbi,
            address: adminAddress,
            functionName: 'rent',
            args: [_tokenId]
        })
    }

    return (
        <div>
            <h1>Rent</h1>
            <input
                type="text"
                placeholder='Enter TokenId'
                value={tokenId}
                onChange={(e) => setTokenId(e.target.value)}
            />
            <button onClick={handleRent}>rent</button>
        </div>
    )
    
}

function Film() {
        
    const { writeContract } = useWriteContract();
    const [room,setRoom] = useState('');

    function handleFilm() {
        
        const _room = Number(room);

        writeContract({
            abi: adminAbi,
            address: adminAddress,
            functionName: 'film',
            args: [_room],
        })
    }

    return (
        <div>
            <h1>Film</h1>
            <input
                type="text"
                placeholder='Enter Room'
                value={room}
                onChange={(e) => setRoom(e.target.value)}
            />
            <button onClick={handleFilm}>Film</button>
        </div>
    )
}

function NFTList() {
    
    type NFT = {
        number: number;
        price: bigint;
        awardUSTD: bigint;
        awardToken: bigint;
        isRenting: boolean;
        isSelling: boolean;
    }

    type Seat = {
        room: number;
        seat: number;
    }

    const [NFTdata,setNFTdata] = useState(null);

    const {data: NFTsData} = useReadContract({
        abi: NFTAbi,
        address: NFTAddress,
        functionName: 'getAllNFT',
        args: [],
    })

    const NFTs = (NFTsData || []);

    const [Seatdata,setSeatdata] = useState(null);

    const {data: SeatsData} = useReadContract({
        abi: NFTAbi,
        address: NFTAddress,
        functionName: 'getAllSeats',
        args: [],
    })

    const Seats = (SeatsData || []);

    return (
        <div>
            <h1>NFTList</h1>
            <ul>
                {Seats.map((Seat,index) => (
                    <li key ={index}>
                    <p>TokenID: {index}</p>
                    <p>Room: {Seat.room}</p>
                    <p>Seat: {Seat.seat}</p>
                </li>
                ))}
                {NFTs.map((NFT,index) => (
                    <li key ={index}>
                    <p>TokenID: {index}</p>
                    <p>Number: {NFT.number}</p>
                    <p>Price: {Number(NFT.price)}</p>
                    <p>awardUSDT: {Number(NFT.awardUSDT)}</p>
                    <p>awardUSDT: {Number(NFT.awardToken)}</p>
                    <p>IsRenting: {NFT.isRenting.toString()}</p>
                    <p>IsSelling: {NFT.isSelling.toString()}</p>
                </li>
                ))}
            </ul>
        </div>
    )

}

function BalanceOf() {
    
    const {data: TokenBalance} = useReadContract({
        abi: TokenAbi,
        address: TokenAddress,
        functionName: 'balanceOf',
        args: ['0x70997970C51812dc3A010C7d01b50e0d17dc79C8'],
    })

    const {data: USDTBalance} = useReadContract({
        abi: TokenAbi,
        address: USDTAddress,
        functionName: 'balanceOf',
        args: ['0x70997970C51812dc3A010C7d01b50e0d17dc79C8'],
    })
    return (
        <div>
            <h1>TokenBalance</h1>
            <h2>{Number(TokenBalance)}</h2>
            <h1>USDTBalance</h1>
            <h2>{Number(USDTBalance)}</h2>
        </div>
    )

}

function Withdraw() {
    
    const { writeContract } = useWriteContract();
    const [tokenId,setTokenId] = useState('');

    function handleWithdraw() {
        
        const _tokenId = BigInt(tokenId);

        writeContract({
            abi: adminAbi,
            address: adminAddress,
            functionName: 'withdraw',
            args: [_tokenId],
        })
    }

    return (
        <div>
            <h1>Withdraw</h1>
            <input
                type="text"
                placeholder='Enter TokenId'
                value={tokenId}
                onChange={(e) => setTokenId(e.target.value)}
            />
            <button onClick={handleWithdraw}>Withdraw</button>
        </div>
    )
}

function Mint() {
    
    const {writeContract} = useWriteContract();
    const [tokenId,setTokenId] = useState('');
    const [room,setRoom] = useState('');
    const [seat,setSeat] = useState('');
    const [number,setNumber] = useState('');
    const [price,setPrice] = useState('');
    const [awardUSDT,setAwardUSDT] = useState('');
    const [awardToken,setAwardToken] = useState('');

    

    function handleMint() {
        
        const _tokenId = BigInt(tokenId);
        const _room = Number(room);
        const _seat = Number(seat);
        const _number = Number(number);
        const _price = BigInt(price);
        const _awardUSDT = BigInt(awardUSDT);
        const _awardtoken = BigInt(awardToken);

        
        writeContract({
            abi: NFTAbi,
            address: NFTAddress,
            functionName: 'mint',
            args: [_tokenId,'',_room,_seat,_number,_price,_awardUSDT,_awardtoken],
        })
    }

    return (
        <div>
            <h1>Mint</h1>
            <input
                type="text"
                placeholder='Enter TokenId'
                value={tokenId}
                onChange={(e) => setTokenId(e.target.value)}
            />
            <input
                type="text"
                placeholder='Enter Room'
                value={room}
                onChange={(e) => setRoom(e.target.value)}
            />
            <input
                type="text"
                placeholder='Enter Seat'
                value={seat}
                onChange={(e) => setSeat(e.target.value)}
            />
            <input
                type="text"
                placeholder='Enter Number'
                value={number}
                onChange={(e) => setNumber(e.target.value)}
            />
            <input
                type="text"
                placeholder='Enter Price'
                value={price}
                onChange={(e) => setPrice(e.target.value)}
            />
            <input
                type="text"
                placeholder='Enter AwardUSDT'
                value={awardUSDT}
                onChange={(e) => setAwardUSDT(e.target.value)}
            />
            <input
                type="text"
                placeholder='Enter AwardToken'
                value={awardToken}
                onChange={(e) => setAwardToken(e.target.value)}
            />

            <button onClick={handleMint}>Mint</button>
        </div>
    )
}

export {Buy,Rent,Film,NFTList,BalanceOf,Withdraw,Mint}
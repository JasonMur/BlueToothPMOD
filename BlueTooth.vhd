----------------------------------------------------------------------------------
-- Engineer: 				Jason Murphy
-- Create Date:   		09:00 01/13/2017 
-- Design Name: 			BlueTooth
-- Module Name:   		BlueTooth - Behavioral 
-- Project Name: 			Blue Tooth Interface
-- Target Devices: 		Spartan 6 xc6slx9-3tgg144
-- Tool versions: 		ISE 14.7
-- Description: 			Reads BuleTooth data from UART via I2C on
--								Raspberry Pi
-- Dependencies: 			
-- Revision 				0.01 - File Created
-- Additional Comments: 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity BlueTooth is Port ( 
	sck : inout  STD_LOGIC;
   sda : inout  STD_LOGIC;
   TxD : out STD_LOGIC;
	RxD : in  STD_LOGIC;
	RTS : out STD_LOGIC;
	CTS : in STD_LOGIC;
   clk50 : in  STD_LOGIC;
	RxDTest : out STD_LOGIC;
	RESET : out STD_LOGIC);
end BlueTooth;

architecture Behavioral of BlueTooth is

component I2CInt port( 
	sda, sck : inout std_logic := 'Z';
	clk50 : in std_logic; 
	Bsy : in std_logic;	
	regAddr : out std_logic_vector (7 downto 0);
	regDataIn : in std_logic_vector (7 downto 0);
	regDataOut : out std_logic_vector (7 downto 0);
	readData, writeData : out std_logic := '1';
	sdaTest, sckTest : out std_logic);
end component; 

component UART generic (baudRateCount: integer := 434);
Port (Clk50 : in STD_LOGIC;
	TxD : out STD_LOGIC;
	RxD : in  STD_LOGIC;
	RTS : out STD_LOGIC;
	CTS : in STD_LOGIC;
	Din : in STD_LOGIC_VECTOR (7 downto 0);
	DinNotRdy, DoutNotRdy : in STD_LOGIC;
	Dout : out  STD_LOGIC_VECTOR (7 downto 0);
   Doutvalid, DinValid : out  STD_LOGIC);
end component;

component fifo port (  
	clk50 : in std_logic;
   readData : in std_logic;   --Read Data from FIFO.  Active low data read on falling edge
   writeData : in std_logic;  --Write Data to FIFO.  Active low data written on falling edge
   dataOut : out std_logic_vector(7 downto 0);    --output data from FIFO
   dataIn : in std_logic_vector (7 downto 0);     --input data to FIFO
   empty, full : out std_logic);     --set as '1' when FIFO overrun occurs
end component;

signal regAddrSig : std_logic_vector(7 downto 0);
signal dataFromRxFIFOSig, dataToRxFIFOSig : std_logic_vector(7 downto 0);
signal dataFromTxFIFOSig, dataToTxFIFOSig : std_logic_vector(7 downto 0);
signal DinNotRdySig, DoutNotRdySig : STD_LOGIC;
signal DinValidSig, DoutValidSig : STD_LOGIC;
signal WriteDataSig, ReadDataSig : STD_LOGIC;
signal FIFOReadDataSig, FIFOWriteDataSig : STD_LOGIC;

begin

process(clk50) is
	begin
		if rising_edge(clk50) then	
			if regAddrSig /= "00000000" then
				FIFOWriteDataSig <= WriteDataSig;
				FIFOReadDataSig <= ReadDataSig;
			end if;
		end if;
end process;

I2C1 : I2CInt port map (
	sda => sda,
	sck => sck,
	clk50 => clk50, 
	bsy => '0',
	regAddr => regAddrSig,
	regDataIn => dataFromRxFIFOSig,
	regDataOut => dataToTxFIFOSig,
	readData => readDataSig,
	writeData => writeDataSig
);

Rxfifo : fifo port map (
	clk50 => clk50,
   readData => FIFOReadDataSig,
   writeData => DoutValidSig,
   dataOut => dataFromRxFIFOSig,
   dataIn => dataToRxFIFOSig,
	full => DoutNotRdySig
);

Txfifo : fifo port map (
	clk50 => clk50,
   readData => DinValidSig,
   writeData => FIFOWriteDataSig,
   dataOut => dataFromTxFIFOSig,
   dataIn => dataToTxFIFOSig,
	empty => DinNotRdySig
);

UART1 : UART Port map (
	clk50 => clk50,
	TxD => TxD,
	RxD => RxD,
	RTS => RTS,
	CTS => CTS,
	Din => DataFromTxFIFOSig,
	DinNotRdy => DinNotRdySig,
	DoutNotRdy => DoutNotRdySig,
   Dout => DataToRxFIFOSig,
   Doutvalid => DoutValidSig,
	DinValid => DinValidSig
);

RxDTest <= RxD;
RESET <= '1';

end Behavioral;


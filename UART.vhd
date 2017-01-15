----------------------------------------------------------------------------------
-- Engineer: 				Jason Murphy
-- Create Date:   		09:00 01/13/2017 
-- Design Name: 			UART
-- Module Name:   		UART - Behavioral 
-- Project Name: 			GPSInterface
-- Target Devices: 		Spartan 6 xc6slx9-3tgg144
-- Tool versions: 		ISE 14.7
-- Description: 			8 bit output UART receiver
--								Fixed at 115Kbaud, no parity
--								receive only RTS/CTS loop Ctrl
--								Revision V0.01
-- Dependencies: 			
-- Revision 				0.01 - File Created
-- Additional Comments: 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity UART is generic (baudRateCount: integer := 434);  --Clock / BAUD_RATE
    -- 2400 : 20833
    -- 9600 : 5208
    -- 115200 : 434
    --1562500 : 32
    -- 2083333 : 24
	 
Port (clk50 : in STD_LOGIC;
	TxD : out STD_LOGIC;
	RxD : in  STD_LOGIC;
	RTS : out STD_LOGIC;
	CTS : in STD_LOGIC;
	Din : in STD_LOGIC_VECTOR (7 downto 0);
	DinNotRdy, DoutNotRdy : in STD_LOGIC;
	Dout : out  STD_LOGIC_VECTOR (7 downto 0);
   Doutvalid, DinValid : out  STD_LOGIC);
end UART;

architecture Behavioral of UART is

signal RxDBuff : std_logic_vector(1 downto 0);
signal rxCounter : integer range 0 to 1048575 := 0;
signal txCounter : integer range 0 to baudRateCount := 0;
type rxCmdSequence is (unknown, idle, startBit, validData, stopBit, error);
signal rxCurrentState : rxCmdSequence := unknown;
signal DoutSig, DinSig : std_logic_vector(7 downto 0);
signal rxBitCount : integer range 0 to 7 := 0;
signal txBitCount : integer range 0 to 8 := 8;

begin

process(clk50)
begin
	if rising_edge(clk50) then
		DoutValid <= '1';
		RxDBuff <= RxDBuff(0) & RxD;
		rxCounter <= rxCounter + 1;
		if rxCounter = 1048575 then
			rxCurrentState <= idle;
		end if;	
		case rxCurrentState is
		when unknown =>
			if RxDBuff = "00" then
				rxCounter <= 0;
			end if;
		when idle =>
			if RxDBuff = "00" then -- at the start bit
				rxCounter <= 0;       -- reset the counter
				rxCurrentState <= startBit;
			end if;
		when startBit =>
			if rxCounter = baudRateCount then  -- half clock cycle into start bit
				rxCurrentState <= validData; -- data is valid
				rxCounter <= 0;
				rxBitCount <= 0;
			end if;
			if RxDBuff = "01" then
				rxCurrentState <= error;   -- unless RxD goes high
			end if;
		when validData =>
			if rxCounter = baudRateCount then   -- measure approx half clock cycle
				DoutSig <= RxDBuff(1) & DoutSig(7 downto 1); -- and sample RxD
				rxCounter <= 0;  -- then reset count
				rxBitCount <= rxBitCount + 1;  --  and increment bit count
				if rxBitCount = 7 then
					rxCurrentState <= stopBit;  -- when 8 bits received
				end if;
			end if;
		when stopBit =>
			if rxCounter = baudRateCount then  -- half clock cycle in
				if RxDBuff = "11" then  -- check stop bit received
					DoutValid <= '0';  -- and indicate valid parallel data 
					rxCurrentState <= idle; 
				else
					rxCurrentState <= error;
				end if;
				rxCounter <= 0;
			end if;
		when error =>
			DoutSig <= "11111111";
			Doutvalid <= '0';
			rxCurrentState <= unknown;
		end case;
	end if;
end process;

process(clk50)
begin
	if rising_edge(clk50) then
		TxD <= '1';
		DinValid <= '1';
		txCounter <= txCounter + 1;
		if txCounter = baudRateCount then
			txCounter <= 0;
			txBitCount <= txBitCount + 1;
			if txBitCount = 0 then
				TxD <= '0'; --Start bit
				DinValid <= '0'; --Get data from FIFO
			elsif txBitCount = 8 then
				txBitCount <= 8;
				if CTS = '1' and DinNotRdy = '0' then
					DinSig <= Din;
					txBitCount <= 0;
				end if;
			else
				TxD <= DinSig(7);
				DinSig <= DinSig(6 downto 0) & '0';
			end if;	
		end if;	
	end if;
end process;

Dout <= DoutSig;
RTS <= not(DoutNotRdy);

end Behavioral;


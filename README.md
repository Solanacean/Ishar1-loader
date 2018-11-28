# Ishar: Legend of the Fortress loader
This loader removes the pointless and incredibly annoying copy protection as well as the stupid requirement to pay gold to save. It is compatible with the version of the game currently being sold by GOG. This work is dedicated to the memory of [https://8bitlegends.com/dr-detergent](Dr. Detergent.)

### Installing
Just throw `ishar1.com` in the game's folder, open `dosboxishar1.conf` in your favorite text editor, replace the line `start.exe` in the autoexec section of the configuration file with `ishar1.com`, save the changes and you're good to go.

### Building from source code
To be able to compile the source code you need MASM, JWASM or [UASM.](http://www.terraspace.co.uk/uasm.html) Build the binary with the following command:

    uasm64.exe -bin ishar1.asm (replace uasm64.exe with uasm32.exe for the 32-bit version of UASM)

which will produce file `ishar1.bin`. Simply rename it to `ishar1.com`

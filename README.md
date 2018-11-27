# Ishar: Legend of the Fortress loader
This loader removes the pointless and utterly annoying copy protection as well as the stupid requirement to pay gold to save. It is compatible with the version of the game being sold by GOG.

## Installing
Just copy ishar1.com to the game folder, open `dosboxishar1.conf` in your favorite text editor, replace `start.exe` in the autoexec section of the configuration file with `ishar1.com` and save the changes.

## Building from source code
To build it from source code you'll need MASM, JWASM or [UASM.](http://www.terraspace.co.uk/uasm.html)

Run the following command:

uasm64.exe -bin ishar1.asm (64-bit version of UASM)<br />
uasm32.exe -bin ishar1.asm (32-bit version of UASM)

`ishar1.bin` will be generated. Rename it to `ishar1.com`

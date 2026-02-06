// Witty ASCII Art Logo for startup display
export const wittyLogo = `
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║     ██╗    ██╗██╗████████╗████████╗██╗   ██╗                ║
║     ██║    ██║██║╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝                ║
║     ██║ █╗ ██║██║   ██║      ██║    ╚████╔╝                 ║
║     ██║███╗██║██║   ██║      ██║     ╚██╔╝                  ║
║     ╚███╔███╔╝██║   ██║      ██║      ██║                   ║
║      ╚══╝╚══╝ ╚═╝   ╚═╝      ╚═╝      ╚═╝                   ║
║                                                              ║
║              💡 Your Intelligent Assistant 💡               ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
`;

export const wittyLogoMinimal = `
 ██╗    ██╗██╗████████╗████████╗██╗   ██╗
 ██║    ██║██║╚══██╔══╝╚══██╔══╝╚██╗ ██╔╝
 ██║ █╗ ██║██║   ██║      ██║    ╚████╔╝ 
 ██║███╗██║██║   ██║      ██║     ╚██╔╝  
 ╚███╔███╔╝██║   ██║      ██║      ██║   
  ╚══╝╚══╝ ╚═╝   ╚═╝      ╚═╝      ╚═╝   
`;

export const wittyLogoBinary = `
01110111 01101001 01110100 01110100 01111001
      w  i        t        t        y

01010111 01001001 01010100 01010100 01011001
      W  I        T        T        Y
`;

export function printWittyLogo(): void {
  console.log(wittyLogo);
}

export function printWittyLogoMinimal(): void {
  console.log(wittyLogoMinimal);
}

export function printWittyLogoBinary(): void {
  console.log(wittyLogoBinary);
}

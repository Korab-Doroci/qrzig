# QrZig
QrZig is a lightweight, efficient QR code generator written in the Zig programming language. It supports generating QR codes with customizable encoding modes, error correction levels, and versions, adhering to the QR code specification. This project is designed for developers who want a fast, native QR code generation tool with minimal dependencies.

## Features
- **QR Code Generation**: Create QR codes from text input with support for various encoding modes (currently focused on byte encoding).

- **Error Correction**: Implements error correction codewords using GF(256) arithmetic for reliable QR codes.

- **Pattern Generation**: Automatically generates finder, alignment, and timing patterns based on the QR version.

- **Masking**: Applies mask patterns to optimize QR code readability.

- **Customizable**: Supports different error correction levels (L, M, Q, H) and dynamically selects the smallest QR version for the input data.

- **Debugging Tools**: Includes a simple console-based QR code printer for visualization.

## Installation
QrZig requires the Zig compiler (version 0.13.0 or later recommended). To build and run the project:
1. Clone the repository:
bash
`
git clone https://github.com/korab-doroci/qrzig.git
cd qrzig
`

2. Build the project:
bash
`
zig build-exe src/main.zig
`

3. Run the executable:
bash
`
./main
`

## Usage
The main entry point demonstrates generating a QR code for the string "Hello, world!" repeated multiple times. You can modify the main function in src/main.zig to generate QR codes for custom strings.

Example:
zig
```
pub fn main() !void {
    const string = "https://example.com";
    const code_version = getMinimumVersion(string.len, .byte, .M);
    var code = Code{ .ecl = .M, .version = code_version };
    generateTimingPattern(&code);
    generateAllFinderPatterns(&code);
    generateAllAlignmentPatterns(&code);
    generateFormatInfo(&code);
    generateDarkBit(&code);

    const encoded_data = try getEncodedData(string, code_version, .byte, .M);
    const error_correction_codewords = try generateErrorCodewords(&encoded_data, &getGeneratorPolynomial(26));
    applyModules(&code, &encoded_data ++ error_correction_codewords.buffer);
    applyMaskPattern(&code, 0b1);
    printCode(&code);
}
```

This will output a QR code to the console using ASCII characters (██ for dark modules, spaces for light modules).

## Project Structure
* `src/main.zig`: Contains the core QR code generation logic and the main function.

* `src/types.zig`: Defines types, constants, and helper functions (e.g., Code, EncodingMode, GF(256) tables).

* **Dependencies**: Relies on Zig’s standard library (std) for utilities like bit writing and memory management.

## Current Limitations
* Only byte encoding is fully implemented; other modes (numeric, alphanumeric, kanji) are planned.

* Limited support for higher QR versions with multiple error correction blocks (work in progress).

* Mask pattern selection is static (uses mask 0b1); dynamic mask evaluation is not yet implemented.

* Output is console-based; image export functionality is not included.

## Roadmap
* Add support for all encoding modes (numeric, alphanumeric, kanji).

* Implement full error correction block interleaving for higher versions.

* Support dynamic mask pattern selection with penalty scoring.

* Add image export (e.g., PNG) as an optional feature.

* Improve documentation and add unit tests.

## Contributing
Contributions are welcome! Feel free to open issues or submit pull requests for bug fixes, features, or optimizations. To contribute:

1. Fork the repository.

2. Create a feature branch (git checkout -b feature-name).

3. Commit your changes (git commit -m "Add some feature").

4. Push to the branch (git push origin feature-name).

5. Open a pull request.

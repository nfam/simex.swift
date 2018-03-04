var fs = require("fs");

const sourceDir = __dirname + "/../Sources/Simex";
const ouputFile = __dirname + "/../dist/Simex.swift";

let sb = [];

const items = fs.readdirSync(sourceDir);
for (let i = 0; i < items.length; i += 1) {
    var item = items[i];
    if (!item.endsWith(".swift")) {
        continue
    }
    let content = fs.readFileSync(sourceDir + "/" + item, "utf8")
    .split('\n')
    .map(line => {
        if (line.trim().startsWith("internal")) {
            return line.replace("internal", "fileprivate")
        }
        else {
            return line;
        }
    })
    .join('\n');

    sb.push(content)
}

fs.writeFileSync(ouputFile, sb.join('\n'), "utf8");

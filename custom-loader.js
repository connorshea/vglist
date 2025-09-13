module.exports = function (content, sourceMap, meta) {
    if (sourceMap && this.resourcePath && this.resourcePath.endsWith(".vue")) {
        this.resourcePath += ".ts"
    }
    return content
}

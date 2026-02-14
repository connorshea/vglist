export default function (content, sourceMap, _meta) {
  if (sourceMap && this.resourcePath && this.resourcePath.endsWith(".vue")) {
    this.resourcePath += ".ts";
  }
  return content;
}

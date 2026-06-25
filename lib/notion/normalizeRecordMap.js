/**
 * 兼容 Notion 新「数据源(data source)」模型返回的多层嵌套结构。
 *
 * 旧模型: recordMap.block[id] = { role, value: { id, type, ... } }
 * 新模型: recordMap.block[id] = { value: { value: { id, type, ... }, role } }
 *          ——真实数据被多包了一层 value。
 *
 * react-notion-x / NotionNext 全部按旧结构读取 record.value，新结构会让
 * record.value.type === undefined，于是数据库被判定为空（getSiteData 里
 * "is not a database" → EmptyData），首页拿到 0 篇文章。
 *
 * 这里把多包的层级剥掉，恢复成标准的 { role, value } 结构。
 * 仅对已知的 record 表生效，collection_query / signed_urls 等非 {value,role}
 * 结构保持原样。
 */

// 形如 { id: { role, value } } 的标准 record 表
const RECORD_TABLES = [
  'block',
  'collection',
  'collection_view',
  'notion_user',
  'space',
  'team',
  'custom_emoji',
  'comment',
  'discussion'
]

const MAX_UNWRAP_DEPTH = 5

/**
 * 把单条多层嵌套的 record 剥成标准 { role, value }。
 * 判定依据：真实数据对象一定带 id；若 record.value 没有 id 却内含 value，
 * 说明 value 被多包了一层，需要继续往里剥。
 * @param {*} record
 * @returns {*} 新的标准结构 record（不修改入参）
 */
function unwrapRecord(record) {
  let current = record
  let depth = 0
  while (
    current &&
    current.value &&
    typeof current.value === 'object' &&
    current.value.id === undefined &&
    current.value.value &&
    typeof current.value.value === 'object' &&
    depth < MAX_UNWRAP_DEPTH
  ) {
    current = {
      role: current.value.role ?? current.role,
      value: current.value.value
    }
    depth++
  }
  return current
}

/**
 * 归一化整个 recordMap（原地替换各表内的 record，便于在大对象上避免深拷贝；
 * 调用方应在数据刚抓取、尚未共享时调用）。
 * @param {*} recordMap
 * @returns {*} 同一个 recordMap 引用
 */
export function normalizeRecordMap(recordMap) {
  if (!recordMap || typeof recordMap !== 'object') {
    return recordMap
  }
  for (const table of RECORD_TABLES) {
    const records = recordMap[table]
    if (!records || typeof records !== 'object') {
      continue
    }
    for (const id of Object.keys(records)) {
      records[id] = unwrapRecord(records[id])
    }
  }
  return recordMap
}

export default normalizeRecordMap

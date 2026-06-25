import { NotionAPI as NotionLibrary } from 'notion-client'
import BLOG from '@/blog.config'
import { normalizeRecordMap } from './normalizeRecordMap'

const notionAPI = withRecordMapNormalization(getNotionAPI())

function getNotionAPI() {
  return new NotionLibrary({
    activeUser: BLOG.NOTION_ACTIVE_USER || null,
    authToken: BLOG.NOTION_TOKEN_V2 || null,
    userTimeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    kyOptions: { 
      mode:'cors',
      hooks: {
        beforeRequest: [
          (request) => {
            const url = request.url.toString()
            if (url.includes('/api/v3/syncRecordValues')) {
              return new Request(
                url.replace('/api/v3/syncRecordValues', '/api/v3/syncRecordValuesMain'),
                request
              )
            }
            return request
          }
        ]
      }
    }
  })
}

/**
 * 包装 NotionAPI 实例：对 getPage / getBlocks 返回的 recordMap 做新数据源模型
 * 归一化（剥掉多包的 value 层），使下游 react-notion-x / NotionNext 仍按标准
 * { role, value } 结构读取。所有 Notion 数据都经此实例进出，故单点拦截即可全覆盖。
 * @param {*} api NotionAPI 实例
 * @returns {*} 同一个实例（方法已被包装）
 */
function withRecordMapNormalization(api) {
  const rawGetPage = api.getPage.bind(api)
  api.getPage = async (...args) => normalizeRecordMap(await rawGetPage(...args))

  const rawGetBlocks = api.getBlocks.bind(api)
  api.getBlocks = async (...args) => {
    const res = await rawGetBlocks(...args)
    if (res?.recordMap) {
      normalizeRecordMap(res.recordMap)
    }
    return res
  }

  return api
}

export default notionAPI

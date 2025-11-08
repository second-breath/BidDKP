-- === Priority map (higher is better) ===
local BID_DKP_ROLL_PRIORITY = {
    ms  = 3,
    os   = 2,
    tmog  = 1,
  }




-- Normalize just in case (handles typos like "MainSpeck/Offspeck")
function BidDKP_NormalizeType(t)
    if not t then return nil end
    t = string.lower(t)
    if t == "mainspec"  or t == "ms" then return "ms" end
    if t == "offspec"   or t == "os" then return "os"  end
    if t == "transmog"  or t == "mog" then return "tmog" end
    return nil
end

-- Decide if candidate should replace current
function BidDKP_ShouldReplaceRoll(current, candidate)
    if not candidate then return false end
    if not current then return true end

    if current.name and candidate.name and current.name == candidate.name then
      return false
  end
  
    local pc = BID_DKP_ROLL_PRIORITY[current.type]  or 0
    local pn = BID_DKP_ROLL_PRIORITY[candidate.type] or 0
  
    if pn > pc then return true end
    if pn < pc then return false end
  
    -- same type: higher value wins
    local cv = current.rollValue or -1
    local nv = candidate.rollValue or -1
    if nv > cv then return true end
  
    -- tie -> keep current
    return false
  end
  
  -- Your existing helper (left as-is)
function BidDKP_TypeFromRange(minv, maxv)
    if minv ~= 1 then return nil end
    if maxv == 100 then return "MainSpec" end
    if maxv == 99  then return "Offspec"  end
    if maxv == 50  then return "Transmog" end
    return nil
  end
  
command: "cd ym.widget; /Users/someuser/.rbenv/shims/bundle exec ruby metrika.rb"
refreshFrequency: 3600000
render: (output) -> """
<div class="resource-name">My website</div>
<div id="items">
</div>
"""

update: (output, domEl) ->
  addItem = (name, value, className) ->
    $item = $('<div class="data-item">')
    $items.append $item
    $item.append "<div class=\"data-label\">#{name}</div>"
    $item.append "<div class=\"data-value#{className}\">#{value}</div>"
    $item

  makeChart = (values, maxValue, $el) ->
    $sparklines = $('<div class="data-sparkline-container">')
    $el.append $sparklines

    for v in values
      do (v) ->
        barHeight = Math.round v * 100 / maxValue
        barHeight = 3 if barHeight < 3
        barTop = 100 - barHeight
        $sparklines.append "<div class=\"data-sparkline-item\" style=\"top: #{barTop}%; height: #{barHeight}%;\">"

  getDirectionClass = (current, previous) ->
    className = ''
    if current - previous > 0
      className = ' data-grow'
    if todayVisits - previousVisits < 0
      className = ' data-fall'
    className

  $items = $(domEl).find '#items'
  $items.empty()

  combinedData = $.parseJSON(output)

  # get two last array elements
  [..., previousVisits, todayVisits] = combinedData.visits

  # find out if there was a growth in visits today
  directionClass = getDirectionClass todayVisits, previousVisits
  $item = addItem 'Visits', todayVisits, directionClass

  # get maximum value in array to build a chart
  maxVisitsCount = Math.max combinedData.visits...
  makeChart combinedData.visits, maxVisitsCount, $item

  for goal in combinedData.goals
    do (goal) ->
      [..., previousHits, todayHits] = goal.hits
      directionClass = getDirectionClass todayHits, previousHits
      $item = addItem goal.name, todayHits, directionClass
      maxHits = Math.max goal.hits...
      makeChart goal.hits, maxHits, $item



style: """
divider-color = #fff
text-color = #fff
label-color = #fff
data-fall-color = #ea6153
data-grow-color = #19b698
sparkline-color = #fff

top: 200px
left: 300px
font-family: "Helvetica Neue"
font-size: 11px

.resource-name
  font-size: 12px
  color: text-color
  margin-left: 10px
  margin-bottom: 10px

.data-item
  color: text-color
  height: 10px
  padding: 10px
  border-top: 1px solid rgba(divider-color, 0.3)
  overflow: hidden
  font-size: 12px

.data-label
  float: left
  line-height: 10px
  color: rgba(label-color, 0.6)

.data-value
  float: right
  line-height: 10px
  min-width: 0.5em
  text-align: right

.data-fall
  color: data-fall-color

.data-grow
  color: data-grow-color

.data-sparkline-container
  float: right;
  height: 10px;
  overflow: hidden;
  margin-right: 10px;
  margin-left: 10px;

.data-sparkline-item
  width: 3px;
  min-height: 1px;
  float: left;
  background-color: rgba(sparkline-color, 0.6);
  margin-left: 2px;
  position: relative;
  border-radius: 3px;
  transition: height 1s ease-in-out
"""

import { DataFrameView } from '@grafana/data';
import { GrafanaTheme } from '@grafana/data/types/theme';
import React from 'react';
import CytoscapeComponent from 'react-cytoscapejs';

interface GraphOptions {
  data: DataFrameView;
  yellowThreshold: number;
  redThreshold: number;
  width: number;
  height: number;
  theme: GrafanaTheme;
}

interface HealthModelNode {
  HealthScore: number;
  ComponentName: string;
  Dependencies: string;
}

interface GraphState {
  graphElements: cytoscape.ElementDefinition[];
}

export class HealthModelGraphComponent extends React.Component<GraphOptions, GraphState> {
  graphControl: any;

  constructor(props: GraphOptions) {
    super(props);

    this.graphControl = null;

    // The component state is set initially using the GraphOptions properties.
    // Grafana will update the properties value through the parent component if new data comes in and re-render components
    // However, that will not trigger a state update since the constructor will not run on a re-render.
    // To solve that, React has getDerivedStateFromProps, which will trigger when GraphOptions updates.
    this.state = { graphElements: HealthModelGraphComponent.loadGraphFromData(props.data) };
  }

  static getDerivedStateFromProps(props: GraphOptions, state: GraphState) {
    // This is called when the GraphOptions instance changes and returns the modified component state.
    return { graphElements: HealthModelGraphComponent.loadGraphFromData(props.data) };
  }

  static loadGraphFromData(data: DataFrameView): cytoscape.ElementDefinition[] {
    // Turns a Grafana DataFrameView into a cytoscape ElementDefinition[] that can be used to visualize the graph.
    // Nodes are populated for each 'ComponentName', edges are added for each dependency a component has listed.
    const result: cytoscape.ElementDefinition[] = [];
    data.map((item: HealthModelNode) => {
      const node = {
        data: {
          id: item.ComponentName.toLowerCase(),
          label: item.ComponentName,
          score: item.HealthScore,
        },
      };
      result.push(node);

      if (item.Dependencies !== '') {
        item.Dependencies.split(',').forEach((dep) => {
          const edge = {
            data: {
              source: item.ComponentName.toLowerCase(),
              target: dep.toLowerCase(),
            },
          };
          result.push(edge);
        });
      }
    });

    return result;
  }

  render() {
    const getFillColor = (score: number) => {
      if (score == null) {
        return this.props.theme.palette.gray1;
      }
      if (score <= this.props.redThreshold) {
        return this.props.theme.palette.redBase;
      }
      if (score <= this.props.yellowThreshold) {
        return this.props.theme.palette.yellow;
      }
      return this.props.theme.palette.greenBase;
    };

    let layout = {
      // These are the default layout options for cytoscape breadthfirst.
      name: 'breadthfirst',

      fit: true, // whether to fit the viewport to the graph
      directed: true, // whether the tree is directed downwards (or edges can point in any direction if false)
      padding: 30, // padding on fit
      circle: false, // put depths in concentric circles if true, put depths top down if false
      grid: false, // whether to create an even grid into which the DAG is placed (circle:false only)
      spacingFactor: 1.75, // positive spacing factor, larger => more space between nodes (N.B. n/a if causes overlap)
      boundingBox: undefined, // constrain layout bounds; { x1, y1, x2, y2 } or { x1, y1, w, h }
      avoidOverlap: true, // prevents node overlap, may overflow boundingBox if not enough space
      nodeDimensionsIncludeLabels: false, // Excludes the label when calculating node bounding boxes for the layout algorithm
      roots: undefined, // the roots of the trees
      maximal: false, // whether to shift nodes down their natural BFS depths in order to avoid upwards edges (DAGS only)
      animate: false, // whether to transition the node positions
      animationDuration: 500, // duration of animation in ms if enabled
      animationEasing: undefined, // easing of animation if enabled,
      ready: undefined, // callback on layoutready
      stop: undefined, // callback on layoutstop
    };

    return (
      <CytoscapeComponent
        elements={CytoscapeComponent.normalizeElements(this.state.graphElements)}
        style={{ width: this.props.width, height: this.props.height }}
        userZoomingEnabled={false}
        cy={(cy) => {
          if (this.graphControl !== cy) {
            this.graphControl = cy;
          }
        }}
        layout={layout}
        stylesheet={[
          {
            selector: 'node',
            style: {
              width: '50px',
              height: '50px',
              'background-color': function (e) {
                return getFillColor(e.data('score'));
              },
              'border-color': '#ccc',
              'border-width': 2,
              label: 'data(label)',
            },
          },
          {
            selector: 'edge',
            style: {
              width: 3,
              'line-color': '#ccc',
              'target-arrow-color': '#ccc',
              'target-arrow-shape': 'triangle',
              'arrow-scale': 1.0,
              color: '#777',
            },
          },
        ]}
      />
    );
  }
}

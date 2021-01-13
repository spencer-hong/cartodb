import * as ConnectorActions from '../../../actions/connector';
import * as ConnectorMutations from '../../../mutations/connector';

const datasets = {
  namespaced: true,
  state: {
    connections: null,
    loadingConnections: false
  },
  mutations: {
    setConnections: ConnectorMutations.setConnections,
    setLoadingConnections: ConnectorMutations.setLoadingConnections
  },
  actions: {
    requestConnector: ConnectorActions.requestConnector,
    deleteConnection: ConnectorActions.deleteConnection,
    editExistingConnection: ConnectorActions.editExistingConnection,
    createNewConnection: ConnectorActions.createNewConnection,
    createNewOauthConnection: ConnectorActions.createNewOauthConnection,
    checkOauthConnection: ConnectorActions.checkOauthConnection,
    fetchOAuthFileList: ConnectorActions.fetchOAuthFileList,
    connectionDryrun: ConnectorActions.connectionDryrun,
    fetchConnectionById: ConnectorActions.fetchConnectionById,
    fetchConnectionsList: ConnectorActions.fetchConnectionsList
  }
};

export default datasets;
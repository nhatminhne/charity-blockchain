import React, { Component } from 'react';
import Web3 from 'web3';
import Marketplace from '../abis/Marketplace.json'
import './App.css';

class App extends Component {
  async componentWillMount() {
    await this.loadWeb3()
    await this.loadBlockchainData()
  }

  async loadWeb3() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum)
      await window.ethereum.enable()
    }
    else if (window.web3) {
      window.web3 = new Web3(window.web3.currentProvider)
    }
    else {
      window.alert('Non-Ethereum browser detected. You should consider trying MetaMask!')
    }
  }

  async loadBlockchainData() {
    const web3 = window.web3
    // Load account
    const accounts = await web3.eth.getAccounts()
    this.setState({ account: accounts[0] })
    const networkId = await web3.eth.net.getId()
    const networkData = Marketplace.networks[networkId]
    if(networkData) {
      const marketplace = web3.eth.Contract(Marketplace.abi, networkData.address)
      const productCount = await marketplace.methods.productCount().call()
      this.setState({ productCount })
      // Load products
      for (var i = 1; i <= productCount; i++) {
        const product = await marketplace.methods.products(i).call()
        this.setState({
          products: [...this.state.products, product]
        }) 
      }
      this.setState({ marketplace })
      this.setState({ loading: false})
      console.log(marketplace)
    } else {
      window.alert('Marketplace contract not deployed to detected network.')
    }
  }

  constructor(props) {
    super(props)
    this.state = {
      account: '',
      productCount: 0,
      products: [],
      loading: true
    }
    this.createProduct = this.createProduct.bind(this)
    this.purchaseProduct = this.purchaseProduct.bind(this)
  }

  createProduct(name, price) {
    this.setState({loading: true})
    this.state.marketplace.methods.createProduct(name, price).send({ from: this.state.account })
    .once('receipt', (receipt) => {
      this.setState({ loading: false })
    })
  }

  purchaseProduct(id, price) {
    this.setState({ loading: true })
    this.state.marketplace.methods.purchaseProduct(id).send({ from: this.state.account, value: price })
    .once('receipt', (receipt) => {
      this.setState({ loading: false })
    })
  }

  render() {
    return (
      <div>
        <nav className="navbar navbar-dark fixed-top bg-dark flex-md-nowrap p-0 shadow">
          <a
            className="navbar-brand col-sm-3 col-md-2 mr-0"
            href="http://www.dappuniversity.com/bootcamp"
            target="_blank"
            rel="noopener noreferrer"
          >
            Marketplace
          </a>
        </nav>
        <div className="container-fluid mt-5">
          <div className="row">
            <main role="main" className="col-lg-12 d-flex text-center">
              <div className="content">
                <h1>Add product</h1>
                <form onSubmit={(event) => {
                  event.preventDefault()
                  const name = this.productName.value
                  const price = window.web3.utils.toWei(this.productPrice.value.toString(), 'Ether')
                  this.createProduct(name, price)
                }}>
                  <div className="form-group mr-sm-2">
                    <input
                      id="productName"
                      type="text"
                      ref={(input) => { this.productName = input }}
                      className="form-control"
                      placeholder="Product Name"
                      required />
                  </div>
                  <div className="form-group mr-sm-2">
                    <input
                      id="productPrice"
                      type="text"
                      ref={(input) => { this.productPrice = input }}
                      className="form-control"
                      placeholder="Product Price"
                      required />
                  </div>
                  <button type="submit" className="btn btn-primary">Add Product</button>
                </form>
                <p> </p>
                <h2>Buy Product</h2>
                <table className="table">
                  <thead>
                    <tr>
                      <th scope="col">#</th>
                      <th scope="col">Name</th>
                      <th scope="col">Price</th>
                      <th scope="col">Owner</th>
                      <th scope="col"></th>
                    </tr>
                  </thead>
                  <tbody id="productList">
                  { this.state.products.map((product, key) => {
                      return(
                        <tr key={key}>
                          <th scope="row">{product.id.toString()}</th>
                          <td>{product.name}</td>
                          <td>{window.web3.utils.fromWei(product.price.toString(), 'Ether')} Eth</td>
                          <td>{product.owner}</td>
                          <td>
                            { !product.purchased
                              ? <button
                                  name={product.id}
                                  value={product.price.toString()}
                                  onClick={(event) => {
                                    this.purchaseProduct(event.target.name, event.target.value)
                                  }}
                                >
                                  Buy
                                </button>
                              : null
                            }
                            </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            </main>
          </div>
        </div>
      </div>
    );
  }
}

export default App;
